import React from 'react';
import {createRoot} from 'react-dom/client';
import {createClient,type SupabaseClient} from '@supabase/supabase-js';
import PortalSelection from '../../app/portal-selection';
import '../../app/globals.css';
const root=createRoot(document.getElementById('root')!);
let auth:SupabaseClient;
async function boot(){
 const nativeFetch=window.fetch.bind(window);
 try{
  const r=await nativeFetch('/api/config');if(!r.ok)throw Error('Hospital services are not configured yet.');
  const c=await r.json() as {url:string;key:string};auth=createClient(c.url,c.key);
  // Add credentials only to our own API; external links never receive the token.
  window.fetch=async(input,init)=>{
   const url=new URL(input instanceof Request?input.url:String(input),location.origin);
   if(url.origin===location.origin&&url.pathname.startsWith('/api/')){
    const {data}=await auth.auth.getSession();const headers=new Headers(init?.headers??(input instanceof Request?input.headers:undefined));
    if(data.session)headers.set('Authorization',`Bearer ${data.session.access_token}`);
    return nativeFetch(input,{...init,headers});
   }return nativeFetch(input,init);
  };
  if(location.pathname==='/signout-with-chatgpt'){await auth.auth.signOut();location.replace('/');return}
  // The educational deployment intentionally exposes the demo administrator
  // dashboard without a patient sign-in. Keep the old sign-in URL as a safe
  // home-page redirect so old bookmarks do not lead to a dead end.
  if(location.pathname==='/signin-with-chatgpt'){location.replace('/');return}
  root.render(<><div style={{textAlign:'right',padding:'8px 24px',background:'#edf7f5',fontSize:13}}><span>Public educational demo · fictional data only</span> · <a href="/signout-with-chatgpt">Clear session</a></div><PortalSelection/></>);
 }catch(e){root.render(<><p role="status" style={{padding:16}}>{(e as Error).message}</p><PortalSelection/></>)}
}
void boot();

