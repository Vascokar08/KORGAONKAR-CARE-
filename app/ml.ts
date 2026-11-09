// Small, inspectable supervised text model. No network calls or patient data.
export const corpus = {
 booking: ['book an appointment','schedule a consultation','reserve a visit with a doctor','I need an appointment tomorrow','how can I book a visit','arrange a specialist consultation','make an appointment for cardiology','request a slot for next week'],
 cancellation: ['cancel my appointment','delete a booking','remove my request','change my appointment date','reschedule a visit','I cannot attend my appointment','how do I cancel a visit','move my booking to another day'],
 departments: ['which departments are available','find a doctor','list the specialties','do you have a cardiologist','is there a skin specialist','care for children in pediatrics','orthopedics and general medicine','tell me about dermatology'],
 hours: ['what are the visiting hours','when does the hospital open','outpatient opening times','what time can family visit','are you open on weekends','hospital hours on Saturday','when do clinics close','can visitors come in the evening'],
 diagnostics: ['laboratory tests and imaging','how do I get my lab reports','blood test preparation','where is the diagnostic department','can I get an x ray scan','MRI and ultrasound services','are test results available','tell me about laboratory services'],
 billing: ['how much does a consultation cost','insurance coverage for a visit','what are your fees','pay my hospital bill','do you accept insurance','what is the price for appointments','billing and payment options','is the demo free to use'],
 location: ['where is the hospital located','give me directions','what is the address','visitor parking information','how can I contact reception','hospital phone number','is there wheelchair access','how do I reach the hospital'],
 privacy: ['is my information private','do you store my messages','delete my personal data','how is my data stored','who can see my appointments','privacy policy for chat','are conversations saved','can I use real patient information'],
 preparation: ['what should I bring for my visit','documents needed for appointment','how early should I arrive','prepare for my first consultation','do I need a referral letter','what identification should I carry','checklist for a hospital visit','getting ready for an appointment'],
 greeting: ['hello','hi there','good morning','hey assistant','thank you','thanks for your help','good evening','how can you help me'],
 medical: ['what medicine should I take','diagnose my symptoms','I have a fever','recommend a treatment','what dose should I take','can you assess my pain','is this rash serious','I feel sick and need medical advice'],
 emergency: ['I cannot breathe','severe chest pain','someone is unconscious','heavy bleeding emergency','I need an ambulance','this is an emergency','person is not breathing','urgent emergency help']
} as const;
export type Intent=keyof typeof corpus;
export const labels:Record<Intent,string>={booking:'Book a visit',cancellation:'Manage appointments',departments:'Departments',hours:'Visiting hours',diagnostics:'Diagnostics',billing:'Billing & insurance',location:'Visitor information',privacy:'Privacy',preparation:'Prepare for a visit',greeting:'Welcome',medical:'Medical question',emergency:'Emergency'};
const stops=new Set('a an the is are am i me my you your we our it this that do does can could would should what which how when where for to of in on at with and or please tell about have has need get'.split(' '));
export function tokenize(text:string){return text.toLowerCase().replace(/[^a-z0-9\s]/g,' ').split(/\s+/).filter(w=>w.length>1&&!stops.has(w)).map(w=>w.length>4&&w.endsWith('s')?w.slice(0,-1):w)}
export type Prediction={intent:Intent;score:number;similarity:number;accepted:boolean;tokens:string[];ranking:{intent:Intent;score:number}[];evidence:string};
export function train(data:Record<Intent,readonly string[]>){
 const intents=Object.keys(data) as Intent[],vocab=new Set<string>(),counts={} as Record<Intent,Map<string,number>>,totals={} as Record<Intent,number>,df=new Map<string,number>();
 const documents=intents.flatMap(intent=>data[intent].map(text=>({intent,text,tokens:tokenize(text)})));
 for(const intent of intents){counts[intent]=new Map();totals[intent]=0}
 for(const d of documents){for(const w of d.tokens){vocab.add(w);counts[d.intent].set(w,(counts[d.intent].get(w)||0)+1);totals[d.intent]++}for(const w of new Set(d.tokens))df.set(w,(df.get(w)||0)+1)}
 const idf=(w:string)=>Math.log((1+documents.length)/(1+(df.get(w)||0)))+1;
 function vector(tokens:string[]){const v=new Map<string,number>();for(const w of tokens){if(vocab.has(w))v.set(w,(v.get(w)||0)+idf(w))}const norm=Math.sqrt([...v.values()].reduce((a,b)=>a+b*b,0))||1;for(const [w,n] of v)v.set(w,n/norm);return v}
 const vectors=documents.map(d=>({...d,vector:vector(d.tokens)}));
 function predict(text:string,threshold=.25):Prediction{
  const all=tokenize(text),tokens=all.filter(w=>vocab.has(w));
  const scores=intents.map(intent=>({intent,log:Math.log(data[intent].length/documents.length)+tokens.reduce((s,w)=>s+Math.log(((counts[intent].get(w)||0)+1)/(totals[intent]+vocab.size)),0)}));
  const max=Math.max(...scores.map(s=>s.log));const denom=scores.reduce((s,x)=>s+Math.exp(x.log-max),0);
  const ranking=scores.map(s=>({intent:s.intent,score:Math.exp(s.log-max)/denom})).sort((a,b)=>b.score-a.score);
  const q=vector(tokens);const retrieved=vectors.filter(d=>d.intent===ranking[0].intent).map(d=>({...d,similarity:[...q].reduce((s,[w,n])=>s+n*(d.vector.get(w)||0),0)})).sort((a,b)=>b.similarity-a.similarity)[0];
  return {intent:ranking[0].intent,score:ranking[0].score,similarity:retrieved?.similarity||0,accepted:tokens.length>0&&tokens.length/Math.max(1,all.length)>=.4&&ranking[0].score>=threshold&&(retrieved?.similarity||0)>=.16,tokens,ranking,evidence:retrieved?.text||''};
 }
 return {predict,vocabularySize:vocab.size,exampleCount:documents.length};
}
export const model=train(corpus);
export const validation:{text:string;intent:Intent}[]=[
 {text:'schedule my appointment with a specialist',intent:'booking'},{text:'reserve a consultation',intent:'booking'},
 {text:'delete my appointment request',intent:'cancellation'},{text:'reschedule my booking',intent:'cancellation'},
 {text:'list hospital departments',intent:'departments'},{text:'find a skin specialist',intent:'departments'},
 {text:'visiting times on Saturday',intent:'hours'},{text:'when do outpatient clinics open',intent:'hours'},
 {text:'blood test reports',intent:'diagnostics'},{text:'MRI imaging services',intent:'diagnostics'},
 {text:'consultation fees and insurance',intent:'billing'},{text:'payment for a hospital bill',intent:'billing'},
 {text:'directions to visitor parking',intent:'location'},{text:'reception contact number',intent:'location'},
 {text:'are my chat messages private',intent:'privacy'},{text:'who sees personal data',intent:'privacy'},
 {text:'bring identification and documents',intent:'preparation'},{text:'first visit checklist',intent:'preparation'},
 {text:'hello there',intent:'greeting'},{text:'thanks assistant',intent:'greeting'},
 {text:'recommend medicine for fever',intent:'medical'},{text:'assess this rash',intent:'medical'},
 {text:'unconscious person needs ambulance',intent:'emergency'},{text:'not breathing emergency',intent:'emergency'}
];
export function evaluateModel(){const results=validation.map(x=>({...x,prediction:model.predict(x.text)}));return {results,correct:results.filter(x=>x.intent===x.prediction.intent).length,total:results.length,acceptedCorrect:results.filter(x=>x.intent===x.prediction.intent&&x.prediction.accepted).length}}

