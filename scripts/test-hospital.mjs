import fs from 'node:fs';import ts from 'typescript';import assert from 'node:assert/strict';
const load=async p=>import('data:text/javascript;base64,'+Buffer.from(ts.transpileModule(fs.readFileSync(p,'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText).toString('base64'));
const {buildSlots,recommendDoctors,doctorSeeds,scheduleSeeds,indiaDate}=await load('app/hospital-data.ts');
const {normalizeQuery,retrieve}=await load('app/knowledge.ts');
assert.equal(indiaDate(Date.parse('2026-11-08T20:00:00Z')),'2026-11-09');
const slots=buildSlots(scheduleSeeds,Date.parse('2026-11-08T12:00:00Z'));
assert.equal(new Set(slots.map(s=>s.id)).size,slots.length);
assert.ok(slots.length>0);
for(const s of slots){assert.ok(s.date>'2026-11-08'&&s.date<='2026-12-06');assert.ok(scheduleSeeds.some(d=>d.doctor_id===s.doctor_id&&d.weekday===new Date(s.date+'T12:00:00+05:30').getUTCDay()&&s.time>=d.start&&s.time<d.end))}
const rec=recommendDoctors(doctorSeeds,scheduleSeeds,'skin specialist','gmc',1);assert.equal(rec.length,1);assert.equal(rec[0].doctor.speciality,'Dermatology');
assert.equal(recommendDoctors(doctorSeeds,scheduleSeeds,'astronaut').length,0);
assert.match(normalizeQuery('मुझे त्वचा डॉक्टर चाहिए'),/dermatology/);
assert.match(normalizeQuery('सोमार त्वचा दोक्तोर'),/monday/);
assert.match(normalizeQuery('साँस नहीं आ रही'),/emergency/);
const queries=[['blood stock','blood'],['ORS registration ABHA','ors'],['teleconsultation online','tele'],['DDSSY Goa scheme','ddssy'],['nearby hospital clinic','locator']];
for(const [q,id] of queries)assert.equal(retrieve(q)[0]?.document.id,id,q);
assert.equal(retrieve('quantum spaghetti asteroid').length,0);
console.log(`Hospital checks passed: ${slots.length} correctly scheduled unique slots, doctor ranking, multilingual phrase normalization and retrieval fixtures.`);
