import {env} from 'cloudflare:workers';
import {z} from 'zod';
import {getChatGPTUser} from '../../chatgpt-auth';
import {indiaDate} from '../../hospital-data';
const runtime=()=>env as unknown as {DB:D1Database;ADMIN_EMAIL?:string};
const json=(data:unknown,status=200)=>Response.json(data,{status,headers:{'Cache-Control':'no-store'}});
async function identity(){const user=await getChatGPTUser();const db=runtime().DB;const admin=!!user&&!!runtime().ADMIN_EMAIL&&user.email.toLowerCase()===runtime().ADMIN_EMAIL!.toLowerCase();const grant=user&&!admin?await db.prepare('SELECT role,doctor_id FROM staff_roles WHERE email=?').bind(user.email.toLowerCase()).first<{role:string;doctor_id:string|null}>():null;return {user,role:admin?'administrator':grant?.role||'patient',doctorId:grant?.doctor_id,db}}
const staff=(role:string)=>['administrator','receptionist','doctor'].includes(role);
const allowed=(role:string,assigned:string|null|undefined,doctor:string)=>role==='administrator'||role==='receptionist'||role==='doctor'&&assigned===doctor;
export async function GET(req:Request){try{
 const {user,role,doctorId,db}=await identity();if(!user)return json({error:'Sign in to Korgaonkar Patient Connect.'},401);
 const url=new URL(req.url),action=url.searchParams.get('action')||'queue';
 if(action==='identity')return json({role,doctorId});
 if(action==='resources')return json((await db.prepare('SELECT * FROM hospital_resources ORDER BY kind,name').all()).results);
 if(action==='staff'){if(role!=='administrator')return json({error:'Administrator access required'},403);return json((await db.prepare('SELECT * FROM staff_roles ORDER BY email').all()).results)}
 if(action==='appointments'){if(!staff(role))return json({error:'Staff access required'},403);return json((await db.prepare(`SELECT b.id,b.name,b.status,s.date,s.time,d.name doctor,d.speciality FROM bookings b JOIN appointment_slots s ON s.id=b.slot_id JOIN doctors d ON d.id=s.doctor_id WHERE s.date>=? ${role==='doctor'?'AND d.id=?':''} ORDER BY s.date,s.time LIMIT 100`).bind(indiaDate(),...(role==='doctor'?[doctorId]:[])).all()).results)}
 if(action==='audit'){if(role!=='administrator')return json({error:'Administrator access required'},403);return json((await db.prepare('SELECT action,target,created_at FROM operations_audit ORDER BY created_at DESC LIMIT 50').all()).results)}
 if(action!=='queue')return json({error:'Unknown action'},400);
 const doctor=url.searchParams.get('doctor')||'',day=indiaDate();
 if(!await db.prepare('SELECT id FROM doctors WHERE id=?').bind(doctor).first())return json({error:'Select a doctor'},400);
 const canManage=allowed(role,doctorId,doctor);
 const rows=(await db.prepare('SELECT * FROM queue_tokens WHERE doctor_id=? AND day=? ORDER BY token').bind(doctor,day).all<{id:string;owner:string;token:number;status:string;called_at:string|null;completed_at:string|null}>()).results;
 const history=(await db.prepare("SELECT AVG((julianday(completed_at)-julianday(called_at))*1440) minutes,COUNT(*) samples FROM queue_tokens WHERE doctor_id=? AND status='completed' AND called_at IS NOT NULL AND completed_at>called_at AND (julianday(completed_at)-julianday(called_at))*1440 BETWEEN 2 AND 120").bind(doctor).first<{minutes:number|null;samples:number}>());
 const average=history?.minutes||10,presence=await db.prepare('SELECT * FROM doctor_presence WHERE doctor_id=?').bind(doctor).first<{available:number;updated_at:string}>();
 return json({role,canManage,day,available:presence?.available??1,averageMinutes:Math.round(average),samples:history?.samples||0,estimateMethod:history?.samples?'Observed demo consultation mean':'Illustrative 10-minute baseline',serving:rows.find(r=>r.status==='serving')?.token||null,waiting:rows.filter(r=>r.status==='waiting').length,completed:rows.filter(r=>r.status==='completed').length,tokens:rows.filter(r=>canManage||r.owner===user.userId).map(r=>({id:r.id,token:r.token,status:r.status,mine:r.owner===user.userId,ahead:rows.filter(a=>(a.status==='waiting'&&a.token<r.token)||a.status==='serving'&&a.id!==r.id).length,estimatedMinutes:presence?.available===0?null:Math.round(rows.filter(a=>(a.status==='waiting'&&a.token<r.token)||a.status==='serving'&&a.id!==r.id).length*average)})),updatedAt:new Date().toISOString()});
 }catch{return json({error:'Operations service unavailable. Please retry.'},503)}}
export async function POST(req:Request){
 if(req.headers.get('origin')!==new URL(req.url).origin)return json({error:'Invalid origin'},403);
 try{const {user,role,doctorId,db}=await identity();if(!user)return json({error:'Sign in required'},401);const raw=await req.text();if(raw.length>6000)return json({error:'Request too large'},413);const body=JSON.parse(raw);const now=new Date().toISOString(),day=indiaDate();
 const audit=(action:string,target:string)=>db.prepare('INSERT INTO operations_audit(id,actor,action,target,created_at) VALUES(?,?,?,?,?)').bind(crypto.randomUUID(),user.userId,action,target,now);
 if(body.action==='role'){
  if(role!=='administrator')return json({error:'Administrator access required'},403);
  const b=z.object({email:z.string().email().max(200),role:z.enum(['patient','receptionist','doctor']),doctorId:z.string().max(100).optional()}).parse(body);
  if(b.role==='doctor'&&(!b.doctorId||!await db.prepare('SELECT id FROM doctors WHERE id=?').bind(b.doctorId).first()))return json({error:'Assign an existing doctor profile'},400);
  await db.batch([db.prepare('INSERT INTO staff_roles(email,role,doctor_id) VALUES(?,?,?) ON CONFLICT(email) DO UPDATE SET role=excluded.role,doctor_id=excluded.doctor_id').bind(b.email.toLowerCase(),b.role,b.role==='doctor'?b.doctorId!:null),audit('role',b.role)]);return json({ok:true});
 }
 if(body.action==='resource'){
  if(!['administrator','receptionist'].includes(role))return json({error:'Reception or administrator access required'},403);
  const b=z.object({id:z.string().regex(/^[a-z0-9-]{1,60}$/),name:z.string().trim().min(2).max(80),kind:z.enum(['bed','service']),capacity:z.number().int().min(0).max(1000),available:z.number().int().min(0),status:z.enum(['Available','Limited','Unavailable'])}).refine(b=>b.available<=b.capacity).parse(body);
  await db.batch([db.prepare('INSERT INTO hospital_resources(id,name,kind,capacity,available,status,updated_at) VALUES(?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,kind=excluded.kind,capacity=excluded.capacity,available=excluded.available,status=excluded.status,updated_at=excluded.updated_at').bind(b.id,b.name,b.kind,b.capacity,b.available,b.status,now),audit('resource',b.id)]);return json({ok:true});
 }
 const b=z.object({doctorId:z.string().min(1).max(100),action:z.enum(['walkin','checkin','next','complete','skip','recall','presence']),id:z.string().max(100).optional(),bookingId:z.string().max(100).optional(),available:z.boolean().optional()}).parse(body);
 if(!await db.prepare('SELECT id FROM doctors WHERE id=? AND active=1').bind(b.doctorId).first())return json({error:'Doctor unavailable'},404);
 if(b.action!=='checkin'&&!allowed(role,doctorId,b.doctorId))return json({error:'Not authorized for this doctor queue'},403);
 if(b.action==='presence'){if(b.available===undefined)return json({error:'Availability required'},400);await db.batch([db.prepare('INSERT INTO doctor_presence(doctor_id,available,updated_at) VALUES(?,?,?) ON CONFLICT(doctor_id) DO UPDATE SET available=excluded.available,updated_at=excluded.updated_at').bind(b.doctorId,b.available?1:0,now),audit('presence',b.doctorId)]);return json({ok:true})}
 if(b.action==='walkin'||b.action==='checkin'){
  if(b.action==='checkin'&&!await db.prepare("SELECT b.id FROM bookings b JOIN appointment_slots s ON s.id=b.slot_id WHERE b.id=? AND b.owner=? AND b.status!='cancelled' AND s.doctor_id=? AND s.date=?").bind(b.bookingId||'',user.userId,b.doctorId,day).first())return json({error:'Check-in requires your active appointment for today with this doctor.'},409);
  const id=crypto.randomUUID();await db.batch([db.prepare("INSERT INTO queue_tokens(id,doctor_id,day,token,owner,booking_id,status,created_at) SELECT ?,?,?,COALESCE(MAX(token),0)+1,?,?,'waiting',? FROM queue_tokens WHERE doctor_id=? AND day=?").bind(id,b.doctorId,day,b.action==='checkin'?user.userId:'synthetic-demo',b.action==='checkin'?b.bookingId!:null,now,b.doctorId,day),audit(b.action,id)]);return json({id},201);
 }
 let statement:D1PreparedStatement;
 if(b.action==='next')statement=db.prepare("UPDATE queue_tokens SET status='serving',called_at=? WHERE id=(SELECT id FROM queue_tokens WHERE doctor_id=? AND day=? AND status='waiting' ORDER BY token LIMIT 1) AND NOT EXISTS(SELECT 1 FROM queue_tokens WHERE doctor_id=? AND day=? AND status='serving') AND NOT EXISTS(SELECT 1 FROM doctor_presence WHERE doctor_id=? AND available=0)").bind(now,b.doctorId,day,b.doctorId,day,b.doctorId);
 else if(b.action==='complete')statement=db.prepare("UPDATE queue_tokens SET status='completed',completed_at=? WHERE id=? AND doctor_id=? AND day=? AND status='serving'").bind(now,b.id||'',b.doctorId,day);
 else if(b.action==='skip')statement=db.prepare("UPDATE queue_tokens SET status='skipped' WHERE id=? AND doctor_id=? AND day=? AND status IN ('waiting','serving')").bind(b.id||'',b.doctorId,day);
 else statement=db.prepare("UPDATE queue_tokens SET status='waiting',called_at=NULL WHERE id=? AND doctor_id=? AND day=? AND status='skipped'").bind(b.id||'',b.doctorId,day);
 const result=await db.batch([statement,audit(b.action+'-attempt',b.id||b.doctorId)]);if(!result[0].meta.changes)return json({error:'Queue changed, is paused, or action is unavailable. Refresh and retry.'},409);return json({ok:true});
 }catch(e){if(e instanceof z.ZodError||e instanceof SyntaxError)return json({error:'Invalid operation input'},400);if(String(e).includes('UNIQUE'))return json({error:'Token already exists or another consultation is active. Refresh the queue.'},409);return json({error:'Operation could not be saved. Please retry.'},503)}
}
