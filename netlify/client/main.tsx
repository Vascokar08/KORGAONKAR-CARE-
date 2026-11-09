import React,{useState,type FormEvent} from 'react';
import {createRoot} from 'react-dom/client';
import {createClient,type SupabaseClient} from '@supabase/supabase-js';
import Dashboard from '../../app/dashboard';
import '../../app/globals.css';
const root=createRoot(document.getElementById('root')!);
let auth:SupabaseClient;
function SignIn(){
 const [email,setEmail]=useState(''),[password,setPassword]=useState(''),[message,setMessage]=useState(''),[busy,setBusy]=useState(false),[register,setRegister]=useState(false);
 async function submit(e:FormEvent){e.preventDefault();setBusy(true);setMessage('');try{
  const {error}=register?await auth.auth.signUp({email,password,options:{emailRedirectTo:location.origin}}):await auth.auth.signInWithPassword({email,password});
  if(error)throw error;
  if(register)setMessage('Check your email to confirm your account, then sign in.');else location.assign('/');
 }catch(e){setMessage((e as Error).message)}finally{setBusy(false)}}
 return <main style={{maxWidth:480,margin:'8vh auto',padding:28}}><h1>Korgaonkar Patient Connect</h1><p>Educational demo. Use fictional patient details only.</p><form onSubmit={submit}><label>Email<input type="email" required autoComplete="email" value={email} onChange={e=>setEmail(e.target.value)}/></label><label>Password<input type="password" required minLength={8} autoComplete={register?'new-password':'current-password'} value={password} onChange={e=>setPassword(e.target.value)}/></label><button className="primary" disabled={busy}>{busy?'Please wait…':register?'Create account':'Sign in'}</button></form><p role="status">{message}</p><button onClick={()=>{setRegister(!register);setMessage('')}}>{register?'Already registered? Sign in':'Create a patient account'}</button><p><a href="/">Back to hospital assistant</a></p></main>
}
async function boot(){
 const nativeFetch=window.fetch.bind(window);
 try{
  const r=await nativeFetch('/api/config');if(!r.ok)throw Error('Patient sign-in is not configured yet.');
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
  if(location.pathname==='/signin-with-chatgpt'){root.render(<SignIn/>);return}
  root.render(<><div style={{textAlign:'right',padding:'8px 24px',background:'#edf7f5'}}><a href="/signin-with-chatgpt">Patient sign-in</a> · <a href="/signout-with-chatgpt">Sign out</a></div><Dashboard/></>);
 }catch(e){root.render(<><p role="status" style={{padding:16}}>{(e as Error).message}</p><Dashboard/></>)}
}
void boot();
