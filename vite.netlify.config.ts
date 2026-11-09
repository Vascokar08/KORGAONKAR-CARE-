import {defineConfig} from 'vite';
import react from '@vitejs/plugin-react';
import {resolve} from 'node:path';
export default defineConfig({root:'netlify/client',plugins:[react()],publicDir:resolve('public'),build:{outDir:resolve('netlify-dist'),emptyOutDir:true},resolve:{alias:{'@':resolve('.')}}});
