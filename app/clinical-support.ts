export const labTerms={
 hemoglobin:{name:'Hemoglobin (Hb)',meaning:'Hemoglobin is the protein in red blood cells that carries oxygen.',url:'https://medlineplus.gov/lab-tests/complete-blood-count-cbc/'},
 wbc:{name:'White blood cell count (WBC)',meaning:'White blood cells are part of the immune system. This test counts them in the sample.',url:'https://medlineplus.gov/lab-tests/complete-blood-count-cbc/'},
 platelets:{name:'Platelet count',meaning:'Platelets are blood-cell fragments involved in forming clots to help stop bleeding.',url:'https://medlineplus.gov/lab-tests/complete-blood-count-cbc/'},
 glucose:{name:'Blood glucose',meaning:'This measures the amount of glucose, a type of sugar, in the blood sample. Fasting and other testing conditions matter when a clinician interprets it.',url:'https://medlineplus.gov/lab-tests/blood-glucose-test/'},
 creatinine:{name:'Creatinine',meaning:'Creatinine is a waste product. Clinicians use this measurement with other information when evaluating kidney function.',url:'https://medlineplus.gov/lab-tests/creatinine-test/'}
};
export type LabTerm=keyof typeof labTerms;
export type LabRow={term:LabTerm;value:number;unit:string;low?:number;high?:number};
export function explainRows(rows:LabRow[]){return rows.map(r=>({...r,...labTerms[r.term],flag:r.low===undefined||r.high===undefined?'No complete range provided':r.value<r.low?'Below provided reference range':r.value>r.high?'Above provided reference range':'Within provided reference range',question:'Does this result need follow-up given my symptoms, history, medicines and the laboratory’s testing method?'}))}
export function symptomRoute(text:string){
 const q=text.toLowerCase();
 if(/chest pain|cannot breathe|can.?t breathe|not breathing|unconscious|severe bleeding|slurred speech|one.sided weakness|sudden.*(severe|worst).*headache|worst.*headache|headache.*(sudden|stiff neck|confusion)|emergency|साँस नहीं|सांस नहीं|बेहोश|बेशुद्ध/.test(q))return {emergency:true,department:null,text:'These words may describe an emergency. In India, call 112 or seek emergency medical care now. I cannot assess symptoms, rule out an emergency, or dispatch help.'};
 if(/headache|head ache|डोकेदुखी|सिरदर्द|डोकें दुख/.test(q))return {emergency:false,department:'General medicine',text:'A General Medicine clinician is a starting point for assessing frequent headaches and deciding whether a specialist referral is needed. I cannot diagnose the cause or assess urgency here. A sudden extremely painful headache, or headache with new weakness, speech problems or confusion, needs emergency medical attention. Would you like to see demo General Medicine doctors?'};
 if(/skin|itch|rash|त्वचा|खाज/.test(q))return {emergency:false,department:'Dermatology',text:'Dermatology is the directory category for skin concerns. This match is service navigation, not a diagnosis or an assessment of urgency. A clinician must decide what care is appropriate. Would you like to see demo dermatologists?'};
 if(/knee pain|joint pain|bone pain|हाड|गुडघ/.test(q))return {emergency:false,department:'Orthopedics',text:'Orthopedics is the directory category for bone and joint concerns. This is service navigation, not a diagnosis or urgent-care assessment. If you are unsure, a General Medicine clinician can help choose the next step.'};
 return null;
}
export type Followup={id:string;kind:string;title:string;starts_at:string;frequency:string;ends_on:string;consent:number};
export function nextReminder(r:Followup,now=Date.now()){
 const start=Date.parse(r.starts_at),step=r.frequency==='daily'?86400000:r.frequency==='weekly'?7*86400000:0;
 if(!Number.isFinite(start))return null;const next=step?start+Math.max(0,Math.ceil((now-start)/step))*step:start;
 if(next<now||next>Date.parse(r.ends_on+'T23:59:59+05:30'))return null;return next;
}
