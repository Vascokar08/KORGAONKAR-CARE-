import {readFile,readdir,writeFile,mkdir} from 'node:fs/promises';
import {build} from 'esbuild';
import {pathToFileURL} from 'node:url';
import path from 'node:path';
await mkdir('netlify/migrations',{recursive:true});
await mkdir('work',{recursive:true});
await build({entryPoints:['app/hospital-data.ts'],outfile:'work/hospital-data.mjs',format:'esm',platform:'node'});
const {hospitalSeeds,doctorSeeds,scheduleSeeds,buildSlots}=await import(pathToFileURL(path.resolve('work/hospital-data.mjs')));
let sql='BEGIN;\nCREATE SCHEMA IF NOT EXISTS care;\nSET LOCAL search_path=care,public;\n';
const constraints=[];const tables=[];
for(const file of (await readdir('drizzle')).filter(n=>n.endsWith('.sql')).sort()){
 let contents=(await readFile('drizzle/'+file,'utf8')).replace(/`([^`]+)`/g,'"$1"').replace(/--> statement-breakpoint/g,'');
 contents=contents.replace(/CREATE TABLE "(\w+)" \(([\s\S]*?)\);/g,(_,name,body)=>{
  tables.push(name);
  body=body.replace(/,?\s*FOREIGN KEY ([^\n]+)(?:\n|$)/g,(_,fk)=>{constraints.push(`ALTER TABLE "${name}" ADD FOREIGN KEY ${fk.replace(/,$/,'')};`);return '\n'});
  return `CREATE TABLE IF NOT EXISTS "${name}" (${body});`;
 });
 contents=contents.replace(/CREATE UNIQUE INDEX /g,'CREATE UNIQUE INDEX IF NOT EXISTS ').replace(/ ADD "/g,' ADD COLUMN IF NOT EXISTS "');
 sql+=contents+'\n';
}
// First deployment only: the checked-in migration is run once in a new project.
sql+=constraints.join('\n')+'\n';
const value=v=>typeof v==='number'?String(v):"'"+String(v).replaceAll("'","''")+"'";
function insert(table,rows){for(const r of rows)sql+=`INSERT INTO ${table} (${Object.keys(r).map(k=>'"'+k+'"').join(',')}) VALUES (${Object.values(r).map(value).join(',')}) ON CONFLICT DO NOTHING;\n`}
insert('hospitals',hospitalSeeds);
insert('departments',doctorSeeds.map(d=>({id:d.department_id,hospital_id:d.hospital_id,name:d.speciality})));
insert('doctors',doctorSeeds.map((d,i)=>({...d,fee:400+(i%6)*50})));
insert('doctor_schedules',scheduleSeeds);
insert('appointment_slots',buildSlots(scheduleSeeds).map(s=>({...s,active:1})));
for(const t of tables)sql+=`ALTER TABLE care."${t}" ENABLE ROW LEVEL SECURITY;\n`;
sql+='REVOKE ALL ON SCHEMA care FROM PUBLIC;\nCOMMIT;\n';
await writeFile('netlify/migrations/001_initial.sql',sql);
console.log(`Prepared ${tables.length} Postgres tables and fictional hospital fixtures.`);
