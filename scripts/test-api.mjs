import assert from 'node:assert/strict';
// Local integration test only. Never point this at production.
const base='http://127.0.0.1:5173';
const sign=await fetch(base+'/signin-with-chatgpt?return_to=/',{redirect:'manual'});
const cookie=sign.headers.get('set-cookie')?.split(';')[0];assert.ok(cookie,'Local sign-in cookie missing');
async function post(action,data={},extra={}){const r=await fetch(base+'/api/hospital',{method:'POST',headers:{cookie,Origin:base,'Content-Type':'application/json',...extra},body:JSON.stringify({action,...data})});const text=await r.text();let body;try{body=JSON.parse(text)}catch{body={error:text}}return {status:r.status,body}}
async function get(action){const r=await fetch(base+'/api/hospital?action='+action,{headers:{cookie}});const body=await r.json();assert.equal(r.status,200,JSON.stringify(body));return body}
assert.equal((await fetch(base+'/api/hospital?action=bookings')).status,401);
assert.equal((await post('book',{}, {Origin:'https://untrusted.invalid'})).status,403);
assert.equal((await post('initialize')).status,200);
const cat=await get('catalogue');assert.equal(cat.isAdmin,true);assert.ok(cat.doctors.length>=18);
const slots=(await get('slots&doctor='+cat.doctors[0].id)).filter(s=>s.available);assert.ok(slots.length>=3);
const ids=[];let holiday;
try{
 const attempt=await Promise.all([post('book',{name:'QA Sample One',slotId:slots[0].id,reminder:true}),post('book',{name:'QA Sample Two',slotId:slots[0].id,reminder:false})]);
 assert.deepEqual(attempt.map(r=>r.status).sort(),[201,409]);const winner=attempt.find(x=>x.status===201).body;ids.push(winner.id);assert.equal(winner.status,'awaiting_hospital_confirmation');
 const second=await post('book',{name:'QA Reschedule',slotId:slots[1].id,reminder:false});assert.equal(second.status,201);ids.push(second.body.id);
 assert.equal((await post('reschedule',{id:winner.id,slotId:slots[1].id})).status,409);
 assert.equal((await get('bookings')).find(x=>x.id===winner.id).slot_id,slots[0].id,'Failed reschedule lost original slot');
 assert.equal((await post('reschedule',{id:winner.id,slotId:slots[2].id})).status,200);
 assert.equal((await get('slots&doctor='+cat.doctors[0].id)).find(s=>s.id===slots[0].id).available,1);
 assert.equal((await post('cancel',{id:winner.id})).status,200);
 assert.equal((await get('slots&doctor='+cat.doctors[0].id)).find(s=>s.id===slots[2].id).available,1);
 holiday={hospitalId:cat.doctors[0].hospital_id,date:slots[0].date,reason:'QA test holiday'};
 assert.equal((await post('holiday',holiday)).status,200);
 assert.equal((await post('book',{name:'QA Holiday',slotId:slots[0].id,reminder:false})).status,409);
 assert.equal((await post('removeHoliday',{id:holiday.hospitalId+'-'+holiday.date})).status,200);holiday=undefined;
 assert.equal((await post('slot',{id:slots[0].id,active:false})).status,200);
 assert.equal((await post('book',{name:'QA Closed',slotId:slots[0].id,reminder:false})).status,409);
 assert.equal((await post('slot',{id:slots[0].id,active:true})).status,200);
 const marker='QA feedback '+crypto.randomUUID();assert.equal((await post('feedback',{rating:5,topic:'Chatbot usefulness',comment:marker})).status,201);
 const feedback=(await get('feedback')).find(x=>x.comment===marker);assert.ok(feedback);assert.equal((await post('deleteFeedback',{id:feedback.id})).status,200);
 assert.equal((await post('book',{name:'X',slotId:slots[0].id,reminder:false})).status,400);
 console.log('API checks passed: anonymous access, origin validation, concurrent slot collision, atomic reschedule, cancellation release, holiday/slot blocking, feedback and input validation.');
}finally{for(const id of ids)await post('deleteBooking',{id});if(holiday)await post('removeHoliday',{id:holiday.hospitalId+'-'+holiday.date});await post('slot',{id:slots[0].id,active:true})}

