'use client';
import {useState} from 'react';
import {ArrowRight,HeartPulse,ShieldCheck,Stethoscope,UserRound} from 'lucide-react';
import Dashboard from './dashboard';
import './portal-selection.css';

type Portal='patient'|'staff';

const portals:[Portal,string,string,string][]=[
 ['patient','Patient Portal','Book demo appointments, ask the care assistant, explore doctors and OPD services.','Continue as Patient'],
 ['staff','Staff Portal','Explore the staff workspace, queue tools and hospital operations in the public educational demo.','Continue as Staff'],
];

export default function PortalSelection(){
 const [portal,setPortal]=useState<Portal|null>(null);
 if(portal){
  const isStaff=portal==='staff';
  return <div className="portal-app"><div className="portal-context"><span><strong>{isStaff?'Staff Portal':'Patient Portal'}</strong>{isStaff?' · Public educational demo':' · Korgaonkar Care AI'}</span><button onClick={()=>setPortal(null)}>Change portal</button></div><Dashboard/></div>;
 }
 return <main className="portal-gate"><div className="portal-gate-inner"><div className="portal-mark"><HeartPulse size={28}/></div><span className="eyebrow">KORGAONKAR CARE AI · DEMO HOSPITAL</span><h1>Welcome to Hospital AI Assistant</h1><p className="portal-lead">Your intelligent healthcare companion. Please select how you would like to continue.</p><section className="portal-options" aria-label="Choose a portal">{portals.map(([id,title,description,button])=>{const StaffIcon=id==='staff'?Stethoscope:UserRound;return <article className="portal-card" key={id}><div className="portal-card-icon"><StaffIcon size={28}/></div><span className="portal-card-kicker">OPTION {id==='patient'?'1':'2'}</span><h2>{title}</h2><p>{description}</p><button className="primary" onClick={()=>setPortal(id)}>{button}<ArrowRight size={16}/></button></article>})}</section><p className="portal-note"><ShieldCheck size={15}/>Educational demonstration only · fictional records · no real hospital access</p></div></main>;
}

