import {build} from 'esbuild';
import {build as viteBuild} from 'vite';
import {mkdir} from 'node:fs/promises';
import path from 'node:path';
await mkdir('netlify/functions',{recursive:true});
await build({entryPoints:['netlify/runtime/handler.ts'],outfile:'netlify/functions/api.mjs',bundle:true,platform:'node',format:'esm',target:'node22',packages:'external',plugins:[{name:'portable-runtime',setup(b){b.onResolve({filter:/^(cloudflare:workers|.*\/chatgpt-auth)$/},()=>({path:path.resolve('netlify/runtime/context.ts')}))}}]});
await viteBuild({configFile:'vite.netlify.config.ts'});
