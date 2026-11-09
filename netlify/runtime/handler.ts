import {createClient} from '@supabase/supabase-js';
import {requestContext} from './context';
import * as hospital from '../../app/api/hospital/route';
import * as support from '../../app/api/support/route';
import * as operations from '../../app/api/operations/route';
const json=(data:unknown,status=200)=>Response.json(data,{status,headers:{'Cache-Control':'no-store'}});
export default async function handler(request:Request){
 const path=new URL(request.url).pathname;
 const url=process.env.SUPABASE_URL,key=process.env.SUPABASE_ANON_KEY;
 if(path==='/api/config')return url&&key?json({url,key}):json({error:'Patient sign-in is awaiting deployment configuration.'},503);
 if(path==='/api/health')return json({service:'Korgaonkar Care AI',configured:!!(url&&key&&process.env.DATABASE_URL)});
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
