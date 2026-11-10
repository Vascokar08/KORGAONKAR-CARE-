import {createClient} from '@supabase/supabase-js';
import {requestContext} from './context';
import {getDatabase} from './database';
import * as hospital from '../../app/api/hospital/route';
import * as support from '../../app/api/support/route';
import * as operations from '../../app/api/operations/route';
const json=(data:unknown,status=200)=>Response.json(data,{status,headers:{'Cache-Control':'no-store'}});
// Netlify is the fictional classroom deployment. Keep its admin panel public
// unless an operator explicitly disables it with PUBLIC_DEMO_ADMIN=false.
const publicDemoAdmin=process.env.PUBLIC_DEMO_ADMIN!=='false';
export default async function handler(request:Request){
 const path=new URL(request.url).pathname;
 const url=process.env.SUPABASE_URL,key=process.env.SUPABASE_ANON_KEY;
 if(path==='/api/config')return url&&key?json({url,key}):json({error:'Hospital services are awaiting deployment configuration.'},503);
 if(path==='/api/health'){
  try{await getDatabase().prepare('SELECT id FROM hospitals LIMIT 1').first();return json({service:'Korgaonkar Care AI',configured:!!(url&&key),databaseConnected:true,publicDemoAdmin})}
  catch{return json({service:'Korgaonkar Care AI',databaseConnected:false},503)}
 }
 if(!url||!key||!process.env.DATABASE_URL)return json({error:'Hospital services are awaiting database configuration.'},503);
 try{
  let user=null;
  const authorization=request.headers.get('authorization');
  if(authorization){
   if(!/^Bearer \S+$/.test(authorization))return json({error:'Invalid sign-in session'},401);
   const auth=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
   const {data,error}=await auth.auth.getUser(authorization.slice(7));
   if(error||!data.user?.email||!data.user.email_confirmed_at)return json({error:'Please sign in with a verified email address.'},401);
   user={userId:data.user.id,email:data.user.email,displayName:data.user.email,fullName:null};
  }
  // This is deliberately a shared, fictional identity for the public
  // educational demo. It must never be enabled for real patient deployments.
  if(!user&&publicDemoAdmin){
   user={userId:'public-demo-admin',email:process.env.ADMIN_EMAIL||'public-demo-admin@demo.invalid',displayName:'Public demo administrator',fullName:null};
  }
  return await requestContext.run({user},async()=>{
   if(path==='/api/appointments')return user?json(request.method==='GET'?[]:{error:'Use the current appointment booking form.'},request.method==='GET'?200:410):json({error:'Please sign in.'},401);
   const route=({'/api/hospital':hospital,'/api/support':support,'/api/operations':operations} as Record<string,Record<string,(r:Request)=>Promise<Response>>>)[path];
   const fn=route?.[request.method];
   if(!fn)return json({error:'Not found'},404);
   return fn(request);
  });
 }catch{ return json({error:'The hospital service is temporarily unavailable.'},503) }
}
export const config={path:'/api/*'};

