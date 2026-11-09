import {env} from 'cloudflare:workers';
import {z} from 'zod';
import {getChatGPTUser} from '../../chatgpt-auth';
import {hospitalSeeds,doctorSeeds,scheduleSeeds,specialties,buildSlots,indiaDate,type Schedule} from '../../hospital-data';
const json=(data:unknown,status=200)=>Response.json(data,{status,headers:{'Cache-Control':'no-store'}});
const runtime=()=>env as unknown as {DB:D1Database;ADMIN_EMAIL?:string};
const activeSlot=`SELECT s.id FROM appointment_slots s JOIN doctors d ON d.id=s.doctor_id WHERE s.id=? AND s.active=1 AND d.active=1 AND s.date>? AND NOT EXISTS (SELECT 1 FROM holidays h WHERE h.hospital_id=d.hospital_id AND h.date=s.date)`;
const bookingSelect=`SELECT b.*,s.date,s.time,d.name AS doctor,d.speciality,d.id AS doctor_id,h.name AS hospital FROM bookings b JOIN appointment_slots s ON b.slot_id=s.id JOIN doctors d ON s.doctor_id=d.id JOIN hospitals h ON d.hospital_id=h.id`;
async function admin(){const user=await getChatGPTUser();return {user,isAdmin:!!user&&!!runtime().ADMIN_EMAIL&&user.email.toLowerCase()===runtime().ADMIN_EMAIL?.toLowerCase()}}
function inserts(db:D1Database,table:string,columns:string[],rows:unknown[][],suffix=''){
 const out:D1PreparedStatement[]=[];const size=Math.floor(90/columns.length);
 for(let n=0;n<rows.length;n+=size){const chunk=rows.slice(n,n+size);out.push(db.prepare(`INSERT INTO ${table} (${columns.join(',')}) VALUES ${chunk.map(()=>`(${columns.map(()=>'?').join(',')})`).join(',')} ${suffix}`).bind(...chunk.flat()))}return out;
}
async function generate(db:D1Database,doctorId?:string){
 const schedules=(await db.prepare('SELECT * FROM doctor_schedules'+(doctorId?' WHERE doctor_id=?':'')).bind(...(doctorId?[doctorId]:[])).all<Schedule>()).results;
 const statements=inserts(db,'appointment_slots',['id','doctor_id','date','time','active'],buildSlots(schedules).map(s=>[s.id,s.doctor_id,s.date,s.time,1]),'ON CONFLICT(id) '+(doctorId?'DO UPDATE SET active=1':'DO NOTHING'));
 for(let n=0;n<statements.length;n+=80)await db.batch(statements.slice(n,n+80));
}
export async function GET(req:Request){try{
 const db=runtime().DB,{user,isAdmin}=await admin(),url=new URL(req.url),action=url.searchParams.get('action')||'catalogue';
 if(action==='catalogue'){
  const data=await db.batch([db.prepare('SELECT * FROM hospitals'),db.prepare('SELECT * FROM doctors ORDER BY name'),db.prepare('SELECT * FROM doctor_schedules'),db.prepare('SELECT * FROM departments'),db.prepare('SELECT * FROM holidays WHERE date>=?').bind(indiaDate())]);
  return json({hospitals:data[0].results,doctors:data[1].results,schedules:data[2].results,departments:data[3].results,holidays:data[4].results,isAdmin,signedIn:!!user});
 }
 if(action==='slots'){
  const rows=await db.prepare(`SELECT s.id,s.doctor_id,s.date,s.time,CASE WHEN b.id IS NULL THEN 1 ELSE 0 END AS available FROM appointment_slots s JOIN doctors d ON d.id=s.doctor_id LEFT JOIN bookings b ON b.slot_id=s.id AND b.status!='cancelled' WHERE s.doctor_id=? AND s.date>? AND s.active=1 AND d.active=1 AND NOT EXISTS (SELECT 1 FROM holidays h WHERE h.hospital_id=d.hospital_id AND h.date=s.date) ORDER BY s.date,s.time`).bind(url.searchParams.get('doctor')||'',indiaDate()).all();return json(rows.results);
 }
 if(!user)return json({error:'Please sign in to view your saved requests.'},401);
 if(action==='bookings')return json((await db.prepare(bookingSelect+' WHERE b.owner=? ORDER BY b.created_at DESC').bind(user.userId).all()).results);
 if(action==='feedback')return json((await db.prepare('SELECT id,rating,topic,comment,created_at FROM feedback WHERE owner=? ORDER BY created_at DESC').bind(user.userId).all()).results);
 if(action==='adminSlots'){
  if(!isAdmin)return json({error:'Administrator access required.'},403);
  return json((await db.prepare('SELECT * FROM appointment_slots WHERE doctor_id=? AND date>? ORDER BY date,time LIMIT 150').bind(url.searchParams.get('doctor')||'',indiaDate()).all()).results);
 }
 if(action==='analytics'){
  if(!isAdmin)return json({error:'Only the configured demo administrator can access analytics.'},403);
  const rows=await db.batch([db.prepare('SELECT intent,SUM(count) AS count,SUM(duration_total) AS duration_total,SUM(fallback_count) AS fallback_count,SUM(measured_count) AS measured_count FROM usage_totals GROUP BY intent ORDER BY count DESC'),db.prepare('SELECT status,COUNT(*) AS count FROM bookings GROUP BY status'),db.prepare('SELECT COUNT(*) AS count,AVG(rating) AS average FROM feedback'),db.prepare('SELECT team,status,COUNT(*) AS count FROM staff_requests GROUP BY team,status'),db.prepare('SELECT department,SUM(count) AS count FROM department_usage GROUP BY department'),db.prepare("SELECT d.speciality,COUNT(*) AS count FROM bookings b JOIN appointment_slots s ON b.slot_id=s.id JOIN doctors d ON s.doctor_id=d.id WHERE b.status!='cancelled' GROUP BY d.speciality")]);return json({intents:rows[0].results,bookings:rows[1].results,feedback:rows[2].results[0],escalations:rows[3].results,departments:rows[4].results,demand:rows[5].results});
 }
 return json({error:'Unknown action'},400);
 }catch(e){console.error('Hospital read failed',e instanceof Error?e.message:'unknown');return json({error:'Hospital database is unavailable. Please retry.'},503)}}
export async function POST(req:Request){
 if(req.headers.get('origin')!==new URL(req.url).origin)return json({error:'Invalid request origin'},403);
 if(Number(req.headers.get('content-length')||0)>12000)return json({error:'Request too large'},413);
 const {user,isAdmin}=await admin();if(!user)return json({error:'Please sign in to continue.'},401);
 let body:Record<string,unknown>;try{body=z.record(z.unknown()).parse(await req.json())}catch{return json({error:'Invalid request'},400)}
 const db=runtime().DB;
 try{
  if(body.action==='book'){
   const b=z.object({slotId:z.string().max(100),name:z.string().trim().min(2).max(60),reminder:z.boolean()}).parse(body),id='HS-'+crypto.randomUUID();
   const result=await db.prepare(`INSERT INTO bookings(id,owner,name,slot_id,status,reminder,created_at) SELECT ?,?,?,id,'awaiting_hospital_confirmation',?,? FROM (${activeSlot})`).bind(id,user.userId,b.name,b.reminder?1:0,new Date().toISOString(),b.slotId,indiaDate()).run();
   if(!result.meta.changes)return json({error:'This slot is no longer offered. Refresh available slots.'},409);
   return json(await db.prepare(bookingSelect+' WHERE b.id=? AND b.owner=?').bind(id,user.userId).first(),201);
  }
  if(body.action==='reschedule'){
   const b=z.object({id:z.string().max(100),slotId:z.string().max(100)}).parse(body);
   const result=await db.prepare(`UPDATE bookings SET slot_id=? WHERE id=? AND owner=? AND status!='cancelled' AND EXISTS (${activeSlot})`).bind(b.slotId,b.id,user.userId,b.slotId,indiaDate()).run();
   if(!result.meta.changes)return json({error:'The request or new slot is unavailable. Your original request has not changed.'},409);
   return json(await db.prepare(bookingSelect+' WHERE b.id=? AND b.owner=?').bind(b.id,user.userId).first());
  }
  if(body.action==='cancel'){
   const b=z.object({id:z.string().max(100)}).parse(body);const r=await db.prepare("UPDATE bookings SET status='cancelled',reminder=0 WHERE id=? AND owner=? AND status!='cancelled'").bind(b.id,user.userId).run();
   return r.meta.changes?json({ok:true}):json({error:'Active request not found.'},404);
  }
  if(body.action==='deleteBooking'){
   const b=z.object({id:z.string().max(100)}).parse(body);await db.prepare('DELETE FROM bookings WHERE id=? AND owner=?').bind(b.id,user.userId).run();return json({ok:true});
  }
  if(body.action==='reminder'){
   const b=z.object({id:z.string().max(100),enabled:z.boolean()}).parse(body);await db.prepare("UPDATE bookings SET reminder=? WHERE id=? AND owner=? AND status!='cancelled'").bind(b.enabled?1:0,b.id,user.userId).run();return json({ok:true});
  }
  if(body.action==='feedback'){
   const b=z.object({rating:z.number().int().min(1).max(5),topic:z.enum(['Appointment experience','Facilities','Chatbot usefulness']),comment:z.string().trim().max(500)}).parse(body);
   await db.prepare('INSERT INTO feedback(id,owner,rating,topic,comment,created_at) VALUES(?,?,?,?,?,?)').bind(crypto.randomUUID(),user.userId,b.rating,b.topic,b.comment,new Date().toISOString()).run();return json({ok:true},201);
  }
  if(body.action==='deleteFeedback'){const b=z.object({id:z.string().max(100)}).parse(body);await db.prepare('DELETE FROM feedback WHERE id=? AND owner=?').bind(b.id,user.userId).run();return json({ok:true})}
  if(body.action==='usage'){
   const b=z.object({intent:z.enum(['booking','cancellation','departments','hours','diagnostics','billing','location','privacy','preparation','greeting','medical','emergency','unknown']),consent:z.literal(true),durationMs:z.number().int().min(0).max(120000).default(0),fallback:z.boolean().default(false),department:z.string().max(60).optional()}).parse(body),day=indiaDate();
   await db.prepare('INSERT INTO usage_totals(id,day,intent,count,duration_total,fallback_count,measured_count) VALUES(?,?,?,1,?,?,?) ON CONFLICT(id) DO UPDATE SET count=count+1,duration_total=duration_total+excluded.duration_total,fallback_count=fallback_count+excluded.fallback_count,measured_count=measured_count+excluded.measured_count').bind(day+'-'+b.intent,day,b.intent,b.durationMs,b.fallback?1:0,typeof body.durationMs==='number'?1:0).run();if(b.department)await db.prepare('INSERT INTO department_usage(id,department,day,count) VALUES(?,?,?,1) ON CONFLICT(id) DO UPDATE SET count=count+1').bind(day+'-'+b.department,b.department,day).run();return json({ok:true});
  }
  if(!isAdmin)return json({error:'Only the configured demo administrator can change hospital data.'},403);
  if(body.action==='initialize'){
   const stmts=[
    ...inserts(db,'hospitals',['id','name','area','address','url'],hospitalSeeds.map(h=>[h.id,h.name,h.area,h.address,h.url]),'ON CONFLICT(id) DO NOTHING'),
    ...inserts(db,'departments',['id','hospital_id','name'],doctorSeeds.map(d=>[d.department_id,d.hospital_id,d.speciality]),'ON CONFLICT(id) DO NOTHING'),
    ...inserts(db,'doctors',['id','hospital_id','department_id','name','speciality','qualification','experience','languages','active'],doctorSeeds.map(d=>[d.id,d.hospital_id,d.department_id,d.name,d.speciality,d.qualification,d.experience,d.languages,1]),'ON CONFLICT(id) DO NOTHING'),
    ...inserts(db,'doctor_schedules',['id','doctor_id','weekday','start','end'],scheduleSeeds.map(s=>[s.id,s.doctor_id,s.weekday,s.start,s.end]),'ON CONFLICT(id) DO NOTHING')
   ];await db.batch(stmts);await generate(db);return json({ok:true});
  }
  if(body.action==='sampleFees'){await db.batch(doctorSeeds.map((d,i)=>db.prepare("UPDATE doctors SET fee=? WHERE id=? AND fee=0 AND name LIKE '%(Demo)%'").bind(400+(i%6)*50,d.id)));return json({ok:true})}
  if(body.action==='generate'){await generate(db);return json({ok:true})}
  if(body.action==='doctor'){
   const b=z.object({id:z.string().max(80),hospitalId:z.string().max(80),name:z.string().trim().min(2).max(70),speciality:z.string().trim().min(2).max(60),qualification:z.string().max(100),experience:z.number().int().min(0).max(70),languages:z.string().max(100),active:z.boolean(),fee:z.number().int().min(0).max(100000).default(0),weekdays:z.array(z.number().int().min(0).max(6)).min(1).max(7),start:z.string().regex(/^([01]\d|2[0-3]):(00|30)$/),end:z.string().regex(/^([01]\d|2[0-3]):(00|30)$/)}).parse(body);
   if(b.start>=b.end)return json({error:'End time must follow start time.'},400);
   if(!await db.prepare('SELECT id FROM hospitals WHERE id=?').bind(b.hospitalId).first())return json({error:'Hospital not found'},400);
   const id=b.id||'demo-'+crypto.randomUUID();
   const existingDep=await db.prepare('SELECT id FROM departments WHERE hospital_id=? AND name=?').bind(b.hospitalId,b.speciality).first<{id:string}>();
   const dep=existingDep?.id||'dep-'+crypto.randomUUID();
   const statements=[db.prepare('INSERT OR IGNORE INTO departments(id,hospital_id,name) VALUES(?,?,?)').bind(dep,b.hospitalId,b.speciality),db.prepare('INSERT INTO doctors(id,hospital_id,department_id,name,speciality,qualification,experience,languages,active) VALUES(?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,qualification=excluded.qualification,experience=excluded.experience,languages=excluded.languages,active=excluded.active').bind(id,b.hospitalId,dep,b.name,b.speciality,b.qualification,b.experience,b.languages,b.active?1:0),db.prepare('DELETE FROM doctor_schedules WHERE doctor_id=?').bind(id),db.prepare('UPDATE appointment_slots SET active=0 WHERE doctor_id=? AND date>?').bind(id,indiaDate())];
   for(const day of new Set(b.weekdays))statements.push(db.prepare('INSERT INTO doctor_schedules(id,doctor_id,weekday,start,end) VALUES(?,?,?,?,?)').bind(id+'-'+day,id,day,b.start,b.end));
   // Preserve booked slots: changes affect new bookings; existing requests stay visible.
   await db.batch(statements);await db.prepare('UPDATE doctors SET fee=? WHERE id=?').bind(b.fee,id).run();if(b.active)await generate(db,id);return json({ok:true});
  }
  if(body.action==='department'){
   const b=z.object({id:z.string().max(100),name:z.string().trim().min(2).max(60)}).parse(body);
   await db.batch([db.prepare('UPDATE departments SET name=? WHERE id=?').bind(b.name,b.id),db.prepare('UPDATE doctors SET speciality=? WHERE department_id=?').bind(b.name,b.id)]);return json({ok:true});
  }
  if(body.action==='holiday'){
   const b=z.object({hospitalId:z.string().max(80),date:z.string().regex(/^\d{4}-\d{2}-\d{2}$/),reason:z.string().trim().min(2).max(100)}).parse(body);
   if(!Number.isFinite(Date.parse(b.date))||new Date(b.date).toISOString().slice(0,10)!==b.date||b.date<indiaDate())return json({error:'Choose a valid future date.'},400);
   await db.prepare('INSERT INTO holidays(id,hospital_id,date,reason) VALUES(?,?,?,?) ON CONFLICT(id) DO UPDATE SET reason=excluded.reason').bind(b.hospitalId+'-'+b.date,b.hospitalId,b.date,b.reason).run();return json({ok:true});
  }
  if(body.action==='removeHoliday'){const b=z.object({id:z.string().max(120)}).parse(body);await db.prepare('DELETE FROM holidays WHERE id=?').bind(b.id).run();return json({ok:true})}
  if(body.action==='slot'){const b=z.object({id:z.string().max(120),active:z.boolean()}).parse(body);await db.prepare('UPDATE appointment_slots SET active=? WHERE id=?').bind(b.active?1:0,b.id).run();return json({ok:true})}
  return json({error:'Unknown action'},400);
 }catch(e){
  if(e instanceof z.ZodError)return json({error:'Please check the form fields and try again.'},400);
  if(String(e).includes('UNIQUE constraint failed: bookings.slot_id'))return json({error:'Another request took that slot. Choose a different time. Your existing request, if any, is unchanged.'},409);
  console.error('Hospital write failed',e instanceof Error?e.message:'unknown');return json({error:'Could not save the change. Please retry.'},503);
 }
}
