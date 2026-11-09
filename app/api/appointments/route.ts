import {z} from 'zod';
import {getChatGPTUser} from '../../chatgpt-auth';
import {getDb} from '../../../db';
import {appointments} from '../../../db/schema';
import {and,eq,desc} from 'drizzle-orm';
const json=(data:unknown,status=200)=>Response.json(data,{status,headers:{'Cache-Control':'no-store'}});
export async function GET(){
 const user=await getChatGPTUser(); if(!user)return json({error:'Sign in to save and view your demo requests.'},401);
 try{return json(await getDb().select().from(appointments).where(eq(appointments.owner,user.userId)).orderBy(desc(appointments.createdAt)));}catch{return json({error:'The database is unavailable. Please try again.'},503);}
}
export async function POST(req:Request){
 const user=await getChatGPTUser();if(!user)return json({error:'Sign in to save your demo request.'},401);
 if(req.headers.get('origin')!==new URL(req.url).origin)return json({error:'Invalid origin'},403);
 let b;try{b=z.object({name:z.string(),department:z.string(),date:z.string(),time:z.string()}).parse(await req.json());}catch{return json({error:'Invalid request'},400);}
 const today=new Date().toLocaleDateString('en-CA',{timeZone:'Asia/Kolkata'});
 if(!b||typeof b.name!=='string'||b.name.trim().length<2||b.name.length>60||!['General medicine','Cardiology','Pediatrics','Orthopedics','Dermatology','Diagnostics'].includes(b.department)||typeof b.date!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(b.date)||!Number.isFinite(Date.parse(b.date))||new Date(b.date).toISOString().slice(0,10)!==b.date||b.date<=today||b.date>new Date(Date.now()+90*86400000).toISOString().slice(0,10)||!['09:00','10:30','12:00','14:30','16:00'].includes(b.time))return json({error:'Use a demo name, a valid department, and a date within the next 90 days.'},400);
 const row={id:crypto.randomUUID(),owner:user.userId,name:b.name.trim(),department:b.department,date:b.date,time:b.time,createdAt:new Date().toISOString()};
 try{await getDb().insert(appointments).values(row);return json(row,201);}catch{return json({error:'Could not save. Please try again.'},503);}
}
export async function DELETE(req:Request){
 const user=await getChatGPTUser();if(!user)return json({error:'Please sign in.'},401);
 if(req.headers.get('origin')!==new URL(req.url).origin)return json({error:'Invalid origin'},403);
 const id=new URL(req.url).searchParams.get('id');if(!id)return json({error:'Request ID required'},400);
 try{await getDb().delete(appointments).where(and(eq(appointments.id,id),eq(appointments.owner,user.userId)));return json({ok:true});}catch{return json({error:'Could not cancel. Please try again.'},503);}
}

