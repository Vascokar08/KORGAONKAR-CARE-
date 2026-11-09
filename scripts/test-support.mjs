import assert from 'node:assert/strict';import fs from 'node:fs';import ts from 'typescript';
const code=ts.transpileModule(fs.readFileSync('app/clinical-support.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText;
const {explainRows,symptomRoute,nextReminder}=await import('data:text/javascript;base64,'+Buffer.from(code).toString('base64'));
const values=explainRows([9,10,15,16].map(value=>({term:'hemoglobin',value,unit:'sample',low:10,high:15})));
assert.deepEqual(values.map(v=>v.flag),['Below provided reference range','Within provided reference range','Within provided reference range','Above provided reference range']);
assert.equal(explainRows([{term:'glucose',value:3,unit:'sample'}])[0].flag,'No complete range provided');
assert.equal(symptomRoute('frequent headaches').department,'General medicine');
assert.equal(symptomRoute('sudden severe headache').emergency,true);
assert.equal(symptomRoute('headache with slurred speech').emergency,true);
assert.equal(symptomRoute('recommend a drug'),null);
const reminder={starts_at:'2026-11-09T10:00:00+05:30',frequency:'daily',ends_on:'2026-11-12'};
assert.equal(nextReminder(reminder,Date.parse('2026-11-10T11:00:00+05:30')),Date.parse('2026-11-11T10:00:00+05:30'));
assert.equal(nextReminder(reminder,Date.parse('2026-11-13T11:00:00+05:30')),null);
const base='http://127.0.0.1:5173';const sign=await fetch(base+'/signin-with-chatgpt?return_to=/',{redirect:'manual'});const cookie=sign.headers.get('set-cookie')?.split(';')[0];assert.ok(cookie);
async function post(action,data){const r=await fetch(base+'/api/support',{method:'POST',headers:{cookie,Origin:base,'Content-Type':'application/json'},body:JSON.stringify({action,...data})});return {status:r.status,body:await r.json()}}
async function get(action){const r=await fetch(base+'/api/support?action='+action,{headers:{cookie}});assert.equal(r.status,200);return r.json()}
assert.equal((await fetch(base+'/api/support?action=reminders')).status,401);
const report=await post('report',{consent:true,rows:[{term:'glucose',value:15,low:4,high:8,unit:'sample units'}]});assert.equal(report.status,200);assert.equal(report.body.rows[0].flag,'Above provided reference range');
assert.equal((await post('report',{consent:true,rows:[{term:'glucose',value:15,low:8,high:4,unit:'sample'}]})).status,400);
assert.equal((await post('report',{consent:false,rows:[{term:'glucose',value:15,unit:'sample'}]})).status,400);
assert.equal((await post('handover',{team:'Reception',subject:'QA test',message:'Demo only',history:'test conversation',historyConsent:false,consent:true})).status,400);
let handoverId,reminderId,facilityId;
try{
 const h=await post('handover',{team:'Billing',subject:'QA handover',message:'Sample service request',history:'QA fictional history',historyConsent:true,consent:true});assert.equal(h.status,201);handoverId=h.body.id;
 assert.equal((await get('inbox')).find(r=>r.id===handoverId).history,'QA fictional history');
 assert.equal((await post('reply',{id:handoverId,reply:'Demo reception reply. No hospital contacted.'})).status,200);
 assert.equal((await get('handovers')).find(r=>r.id===handoverId).status,'answered_in_demo');
 const start=new Date(Date.now()+86400000).toISOString(),ends=new Date(Date.now()+3*86400000).toISOString().slice(0,10);
 const r=await post('reminder',{kind:'Follow-up visit',title:'QA reminder',startsAt:start,frequency:'daily',endsOn:ends,consent:true});assert.equal(r.status,201);reminderId=r.body.id;
 assert.ok((await get('reminders')).some(r=>r.id===reminderId));
 facilityId='qa-layout-'+crypto.randomUUID();assert.equal((await post('facility',{id:facilityId,hospitalId:'north-demo',name:'QA sample room',building:'Demo',floor:'Ground',room:'QA',directions:'Fictional test route only.'})).status,200);
 assert.ok((await get('facilities')).some(f=>f.id===facilityId));
 console.log('Support checks passed: numeric-range boundaries, symptom navigation, emergency phrase routing, reminder recurrence, authentication, consent enforcement, report validation, handover/reply and layout CRUD.');
}finally{if(handoverId)await post('deleteHandover',{id:handoverId});if(reminderId)await post('deleteReminder',{id:reminderId});if(facilityId)await post('deleteFacility',{id:facilityId})}
