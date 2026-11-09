import {model,labels,type Intent,type Prediction} from './ml';
export type ChatContext={department?:string;intent?:Intent};
export type Answer={text:string;context:ChatContext;prediction:Prediction;source:string;actions:string[]};
const knowledge:Record<Intent,{text:string;source:string;actions:string[]}>= {
 booking:{text:'Create a demo request with Book a visit: choose a department, a date within the next 28 days, and a time. You will need to sign in to save it. This is not a real hospital booking.',source:'Demo booking guide',actions:['Book a visit','My appointments']},
 cancellation:{text:'Open My appointments to cancel, reschedule, or delete a saved demo request. Reschedule checks the new slot before changing your request. No real hospital appointment is affected.',source:'Demo booking guide',actions:['My appointments']},
 departments:{text:'Our sample specialties are General medicine, Cardiology, Pediatrics, Orthopedics, Dermatology, and Diagnostics. Which department would you like to explore?',source:'Sample department directory',actions:['Departments']},
 hours:{text:'Sample hours: outpatient services Monday–Saturday, 9 AM–5 PM; visiting hours daily, 4–6 PM; emergency department 24/7. This is a fictional hospital, so these hours are illustrative.',source:'Sample visitor guide',actions:['Visitor guide']},
 diagnostics:{text:'Our sample Diagnostics service covers laboratory tests and imaging. This demo cannot order tests or show results. Ask your actual hospital about preparation instructions, report availability, and fees.',source:'Sample diagnostics guide',actions:['Departments','Book a visit']},
 billing:{text:'This educational demo takes no payments and does not verify insurance. Ask your actual hospital and insurer about consultation fees, coverage, and payment options.',source:'Demo billing guide',actions:[]},
 location:{text:'Carehaven is fictional and has no real address or phone number. Our sample visitor guide covers reception help, accessible entry, and visitor parking. Contact your actual hospital for directions and accessibility details.',source:'Sample visitor guide',actions:['Visitor guide']},
 privacy:{text:'Messages and conversation context stay in this page session. The classifier runs on your device and does not send chat to an AI service. Demo appointments are saved to your signed-in account; Cancel releases the slot; Delete data removes the stored request. Use fictional names only.',source:'Demo privacy guide',actions:['My appointments']},
 preparation:{text:'For a real appointment, ask your hospital which identification, referral, previous reports, and insurance documents to bring, and when to arrive. Do not upload those documents here. This demo only needs a fictional name.',source:'Sample preparation guide',actions:['Book a visit','Visitor guide']},
 greeting:{text:'Hello! I can help you navigate appointments, hospital departments, visiting hours, diagnostics, billing, and visitor information. What would you like to do?',source:'Assistant service guide',actions:['Book a visit','Departments']},
 medical:{text:'I cannot assess symptoms, diagnose conditions, or recommend medicines or doses. Please speak to a qualified clinician. I can help with hospital service information and the demo booking process.',source:'Medical scope boundary',actions:['Book a visit']},
 emergency:{text:'If you think this is an emergency, contact your local emergency services or go to the nearest emergency department now. This demo cannot assess symptoms, dispatch help, or contact emergency services.',source:'Emergency scope boundary',actions:[]}
};
export function respond(input:string,previous:ChatContext={}):Answer{
 const q=input.toLowerCase();
 const found=[['cardio','Cardiology'],['pediatric','Pediatrics'],['orthop','Orthopedics'],['dermat','Dermatology'],['general medicine','General medicine'],['diagnostic','Diagnostics']].find(([key])=>q.includes(key));
 const department=found?.[1]||previous.department;
 const contextual=/^(and |what about |how about |for (that|it)|book (that|it)|yes\b)/.test(q);
 const expanded=contextual&&previous.intent&&!/hour|time|cost|fee|price|cancel|book|visit/.test(q)?`${input} ${labels[previous.intent]} ${department||''}`:input;
 const prediction=model.predict(expanded);
 let intent:Intent|undefined=prediction.accepted?prediction.intent:undefined;
 // Deterministic safety routing is independent of ML confidence; not clinical triage.
 if(/emergency|ambulance|chest pain|can.?t breathe|cannot breathe|not breathing|unconscious|severe bleeding/.test(q))intent='emergency';
 else if(/symptom|\bpain\b|fever|diagnos(?:e|is|ing)|dose|treatment|sick|rash|headache|medication|suicid|self.harm/.test(q)||(/\bmedicine\b/.test(q)&&!q.includes('general medicine')))intent='medical';
 else if(/^(book (that|it)|yes please)/.test(q)&&previous.intent)intent='booking';
 else if(found&&tokenCount(q)<=3)intent='departments';
 const context={department,intent:intent||previous.intent};
 if(!intent)return {text:'I’m not sure which hospital service you mean. Are you asking about an appointment, a department, visiting hours, or something else? I can only help with service information.',context,prediction,source:'Clarification needed',actions:['Book a visit','Departments','Visitor guide']};
 const item=knowledge[intent];let text=item.text;
 if(department&&intent==='departments')text=`${department} is listed in our sample department directory. Sample outpatient hours are Monday–Saturday, 9 AM–5 PM. You can request a demo visit, but availability is not connected to a real hospital. Would you like to book a demo visit?`;
 if(department&&intent==='booking')text=`For ${department}: ${text}`;
 return {text,context,prediction,source:item.source,actions:item.actions};
}
function tokenCount(s:string){return s.trim().split(/\s+/).length}
export function reply(input:string){return respond(input).text}

