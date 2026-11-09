import {env} from 'cloudflare:workers';import {z} from 'zod';
import {getChatGPTUser} from '../../chatgpt-auth';import {explainRows} from '../../clinical-support';
const runtime=()=>env as unknown as {DB:D1Database;ADMIN_EMAIL?:string};
const json=(body:unknown,status=200)=>Response.json(body,{status,headers:{'Cache-Control':'no-store'}});
async function identity(){const user=await getChatGPTUser();return {user,isAdmin:!!user&&!!runtime().ADMIN_EMAIL&&user.email.toLowerCase()===runtime().ADMIN_EMAIL?.toLowerCase()}}
export async function GET(req:Request){try{const {user,isAdmin}=await identity();if(!user)return json({error:'Please sign in to use this feature.'},401);const action=new URL(req.url).searchParams.get('action'),db=runtime().DB;
 if(action==='reminders')return json((await db.prepare('SELECT * FROM followup_reminders WHERE owner=? ORDER BY starts_at').bind(user.userId).all()).results);
 if(action==='handovers')return json((await db.prepare('SELECT id,team,subject,message,history,history_consent,status,reply,created_at FROM staff_requests WHERE owner=? ORDER BY created_at DESC').bind(user.userId).all()).results);
 if(action==='inbox'){if(!isAdmin)return json({error:'Administrator access required.'},403);return json((await db.prepare('SELECT id,team,subject,message,history,history_consent,status,reply,created_at FROM staff_requests ORDER BY created_at DESC LIMIT 100').all()).results)}
 if(action==='facilities')return json((await db.prepare('SELECT * FROM facility_directory ORDER BY name').all()).results);
 return json({error:'Unknown action'},400);
 }catch{return json({error:'This service is temporarily unavailable.'},503)}}
export async function POST(req:Request){
 if(req.headers.get('origin')!==new URL(req.url).origin)return json({error:'Invalid origin'},403);
 const {user,isAdmin}=await identity();if(!user)return json({error:'Please sign in to use this feature.'},401);
 let body:Record<string,unknown>;try{const raw=await req.text();if(raw.length>15000)return json({error:'Request too large'},413);body=z.record(z.unknown()).parse(JSON.parse(raw))}catch{return json({error:'Invalid request'},400)}
 const db=runtime().DB;
 try{
  if(body.action==='report'){
   const b=z.object({consent:z.literal(true),rows:z.array(z.object({term:z.enum(['hemoglobin','wbc','platelets','glucose','creatinine']),value:z.number().finite().min(0),unit:z.string().trim().min(1).max(30),low:z.number().finite().min(0).optional(),high:z.number().finite().min(0).optional()}).refine(r=>r.low===undefined||r.high===undefined||r.low<=r.high,'Reference lower bound must not exceed upper bound')).min(1).max(10)}).parse(body);
   // Deliberately no database write or logging of report values.
   return json({rows:explainRows(b.rows),note:'Compared only with the reference ranges you entered. Within range does not establish health; outside range does not diagnose disease. This tool cannot identify critical values or urgency. If a report is flagged critical or you have concerning symptoms, contact your treating team promptly.',source:'https://medlineplus.gov/lab-tests/how-to-understand-your-lab-results/'});
  }
  if(body.action==='reminder'){
   const b=z.object({kind:z.enum(['Appointment','Prescribed medication','Medical test','Follow-up visit']),title:z.string().trim().min(2).max(120),startsAt:z.string().datetime({offset:true}),frequency:z.enum(['once','daily','weekly']),endsOn:z.string().regex(/^\d{4}-\d{2}-\d{2}$/),consent:z.literal(true)}).parse(body);
   const start=Date.parse(b.startsAt),end=Date.parse(b.endsOn+'T23:59:59+05:30');if(!Number.isFinite(end)||new Date(b.endsOn).toISOString().slice(0,10)!==b.endsOn||start<=Date.now()||start>Date.now()+90*86400000||end<start||end>Date.now()+91*86400000)return json({error:'Choose a future start and an end within the next 90 days.'},400);
   const id=crypto.randomUUID();await db.prepare('INSERT INTO followup_reminders(id,owner,kind,title,starts_at,frequency,ends_on,consent) VALUES(?,?,?,?,?,?,?,1)').bind(id,user.userId,b.kind,b.title,b.startsAt,b.frequency,b.endsOn).run();return json({id},201);
  }
  if(body.action==='deleteReminder'){const b=z.object({id:z.string().max(100)}).parse(body);await db.prepare('DELETE FROM followup_reminders WHERE id=? AND owner=?').bind(b.id,user.userId).run();return json({ok:true})}
  if(body.action==='handover'){
   const b=z.object({team:z.enum(['Reception','Billing','Nursing']),subject:z.string().trim().min(3).max(100),message:z.string().trim().min(3).max(1000),history:z.string().max(6000),historyConsent:z.boolean(),consent:z.literal(true)}).parse(body);
   if(b.history&&!b.historyConsent)return json({error:'Conversation sharing requires explicit consent.'},400);
   const id='HELP-'+crypto.randomUUID();await db.prepare('INSERT INTO staff_requests(id,owner,team,subject,message,history,history_consent,status,reply,created_at) VALUES(?,?,?,?,?,?,?,\'awaiting_demo_staff\',\'\',?)').bind(id,user.userId,b.team,b.subject,b.message,b.historyConsent?b.history:'',b.historyConsent?1:0,new Date().toISOString()).run();return json({id,status:'awaiting_demo_staff'},201);
  }
  if(body.action==='deleteHandover'){const b=z.object({id:z.string().max(100)}).parse(body);await db.prepare('DELETE FROM staff_requests WHERE id=? AND owner=?').bind(b.id,user.userId).run();return json({ok:true})}
  if(!isAdmin)return json({error:'Administrator access required.'},403);
  if(body.action==='reply'){
   const b=z.object({id:z.string().max(100),reply:z.string().trim().min(2).max(1000)}).parse(body);await db.prepare("UPDATE staff_requests SET reply=?,status='answered_in_demo' WHERE id=?").bind(b.reply,b.id).run();return json({ok:true});
  }
  if(body.action==='facility'){
   const b=z.object({id:z.string().max(100),hospitalId:z.string().max(100),name:z.string().trim().min(2).max(80),building:z.string().max(60),floor:z.string().max(40),room:z.string().max(40),directions:z.string().trim().min(3).max(500)}).parse(body);
   await db.prepare('INSERT INTO facility_directory(id,hospital_id,name,building,floor,room,directions) VALUES(?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,building=excluded.building,floor=excluded.floor,room=excluded.room,directions=excluded.directions').bind(b.id||crypto.randomUUID(),b.hospitalId,b.name,b.building,b.floor,b.room,b.directions).run();return json({ok:true});
  }
  if(body.action==='deleteFacility'){const b=z.object({id:z.string().max(100)}).parse(body);await db.prepare('DELETE FROM facility_directory WHERE id=?').bind(b.id).run();return json({ok:true})}
  return json({error:'Unknown action'},400);
 }catch(e){return e instanceof z.ZodError?json({error:'Check the fields, date range, reference bounds and consent.'},400):json({error:'Could not complete the request. Please retry.'},503)}
}
