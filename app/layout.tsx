import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = {title:'Korgaonkar Care AI | Hospital Assistant',description:'Your hospital visit, made simpler. An educational hospital service assistant.'};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}

