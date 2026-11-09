import assert from 'node:assert/strict';
const base='http://127.0.0.1:5173';
const login=await fetch(base+'/signin-with-chatgpt?return_to=/',{redirect:'manual'}),cookie=login.headers.get('set-cookie')?.split(';')[0];assert.ok(cookie);
async function get(action){const r=await fetch(base+'/api/operations?action='+action,{headers:{cookie}});assert.equal(r.status,200);return r.json()}
async function post(action,data={},headers={}){const r=await fetch(base+'/api/operations',{method:'POST',headers:{cookie,Origin:base,'Content-Type':'application/json',...headers},body:JSON.stringify({action,...data})});const text=await r.text();let body;try{body=JSON.parse(text)}catch{body={error:text}}return {status:r.status,body}}
assert.equal((await fetch(base+'/api/operations?action=resources')).status,401);
assert.equal((await post('walkin',{}, {Origin:'https://untrusted.invalid'})).status,403);
const catalogue=await(await fetch(base+'/api/hospital?action=catalogue',{headers:{cookie}})).json();const doctorId=catalogue.doctors.at(-1).id;
const identity=await get('identity');assert.equal(identity.role,'administrator');
assert.equal((await post('checkin',{doctorId,bookingId:'someone-elses-booking'})).status,409);
assert.equal((await post('resource',{id:'qa-resource',name:'QA resource',kind:'bed',capacity:2,available:3,status:'Available'})).status,400);
assert.equal((await post('role',{email:'test@example.invalid',role:'administrator'})).status,400);
assert.equal((await post('role',{email:'test@example.invalid',role:'doctor',doctorId:'missing'})).status,400);
assert.equal((await post('presence',{doctorId,available:true})).status,200);
// Finish existing test tokens so reruns do not depend on prior queue state.
for(const t of (await get('queue&doctor='+doctorId)).tokens){if(t.status==='serving'||t.status==='waiting')await post('skip',{doctorId,id:t.id})}
const creates=await Promise.all([post('walkin',{doctorId}),post('walkin',{doctorId})]);assert.deepEqual(creates.map(r=>r.status),[201,201]);
let q=await get('queue&doctor='+doctorId);const tokens=q.tokens.filter(t=>creates.some(c=>c.body.id===t.id));assert.equal(new Set(tokens.map(t=>t.token)).size,2);
const calls=await Promise.all([post('next',{doctorId}),post('next',{doctorId})]);assert.deepEqual(calls.map(r=>r.status).sort(),[200,409]);
q=await get('queue&doctor='+doctorId);assert.equal(q.tokens.filter(t=>t.status==='serving').length,1);
const serving=q.tokens.find(t=>t.status==='serving');assert.equal((await post('complete',{doctorId,id:serving.id})).status,200);assert.equal((await post('complete',{doctorId,id:serving.id})).status,409);
const waiting=tokens.find(t=>t.id!==serving.id);assert.equal((await post('skip',{doctorId,id:waiting.id})).status,200);assert.equal((await post('recall',{doctorId,id:waiting.id})).status,200);
await post('presence',{doctorId,available:false});assert.equal((await post('next',{doctorId})).status,409);q=await get('queue&doctor='+doctorId);assert.equal(q.tokens.find(t=>t.id===waiting.id).estimatedMinutes,null);
await post('presence',{doctorId,available:true});await post('next',{doctorId});await post('complete',{doctorId,id:waiting.id});
assert.equal((await get('audit')).some(r=>r.action==='complete-attempt'),true);
console.log('Operations API passed: authentication, origin, invalid resource bounds, forbidden role escalation, invalid doctor grant, owner check-in, concurrent token numbering, concurrent call-next, completion state validation, skip/recall, pause/resume and audit. Synthetic tokens remain in LOCAL test database only.');
