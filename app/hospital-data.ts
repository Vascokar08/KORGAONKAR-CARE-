export const specialties=['General medicine','Cardiology','Pediatrics','Orthopedics','Dermatology','Diagnostics'];
export const days=['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
export type Hospital={id:string;name:string;area:string;address:string;url:string};
export type Doctor={id:string;hospital_id:string;department_id:string;name:string;speciality:string;qualification:string;experience:number;languages:string;active:number;fee?:number};
export type Schedule={id:string;doctor_id:string;weekday:number;start:string;end:string};
export type Slot={id:string;doctor_id:string;date:string;time:string;available:number};
export type Booking={id:string;name:string;slot_id:string;status:string;reminder:number;date:string;time:string;doctor:string;speciality:string;hospital:string;doctor_id:string};
export type Catalogue={hospitals:Hospital[];doctors:Doctor[];schedules:Schedule[];departments:{id:string;hospital_id:string;name:string}[];holidays:{id:string;hospital_id:string;date:string;reason:string}[];isAdmin:boolean;signedIn:boolean};
export const hospitalSeeds:Hospital[]=[
 {id:'gmc',name:'Korgaonkar Multispeciality Hospital (Demo)',area:'Fictional main campus',address:'Sample campus · no real hospital address',url:''},
 {id:'north-demo',name:'Korgaonkar North Clinic (Demo)',area:'Mapusa',address:'Mapusa area · fictional demonstration location',url:''},
 {id:'south-demo',name:'Korgaonkar South Hospital (Demo)',area:'Margao',address:'Margao area · fictional demonstration location',url:''}
];
export const doctorSeeds:Doctor[]=hospitalSeeds.flatMap((h,hi)=>specialties.map((s,i)=>({id:`${h.id}-d${i}`,hospital_id:h.id,department_id:`${h.id}-dep${i}`,name:`Dr. ${String.fromCharCode(65+hi*6+i)} (Demo)`,speciality:s,qualification:i===5?'MD, Radiodiagnosis (sample)':'MBBS, MD/MS (sample)',experience:6+i,languages:'English, Hindi, Konkani (sample)',active:1})));
export const scheduleSeeds:Schedule[]=doctorSeeds.flatMap((d,i)=>[i%2?2:1,i%2?5:3].map(day=>({id:`${d.id}-${day}`,doctor_id:d.id,weekday:day,start:'10:00',end:'12:00'})));
export function indiaDate(now=Date.now()){return new Date(now).toLocaleDateString('en-CA',{timeZone:'Asia/Kolkata'})}
export function buildSlots(schedules:Schedule[],now=Date.now()){
 const rows:{id:string;doctor_id:string;date:string;time:string}[]=[];
 for(let offset=1;offset<=28;offset++){
  const date=indiaDate(now+offset*86400000),weekday=new Date(date+'T12:00:00+05:30').getUTCDay();
  for(const s of schedules.filter(s=>s.weekday===weekday)){
   const [h,m]=s.start.split(':').map(Number),[eh,em]=s.end.split(':').map(Number);
   for(let n=h*60+m;n<eh*60+em;n+=30){const time=`${String(Math.floor(n/60)).padStart(2,'0')}:${String(n%60).padStart(2,'0')}`;rows.push({id:`${s.doctor_id}-${date}-${time.replace(':','')}`,doctor_id:s.doctor_id,date,time})}
  }
 }return rows;
}
export function recommendDoctors(doctors:Doctor[],schedules:Schedule[],query:string,hospital='',weekday=-1){
 const q=query.toLowerCase();const requested=/skin|itch|dermat|त्वचा|खाज/.test(q)?'Dermatology':/heart|cardio|हृदय/.test(q)?'Cardiology':/child|pediatric|बच्च|भुरग/.test(q)?'Pediatrics':/bone|orthop|हड्ड/.test(q)?'Orthopedics':/scan|lab|diagnostic/.test(q)?'Diagnostics':'';
 return doctors.filter(d=>d.active&&(!hospital||d.hospital_id===hospital)&&(weekday<0||schedules.some(s=>s.doctor_id===d.id&&s.weekday===weekday))).map(d=>({doctor:d,score:!q?1:(d.name.toLowerCase().includes(q)?5:0)+(d.speciality.toLowerCase().includes(q)?4:0)+(d.speciality===requested?4:0),reason:requested===d.speciality?'Matches the requested speciality':q?'Name or speciality match':'Matches selected hospital and day'})).filter(x=>x.score>0).sort((a,b)=>b.score-a.score);
}
