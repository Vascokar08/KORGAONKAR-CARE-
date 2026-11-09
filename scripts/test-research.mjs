import fs from 'node:fs';import ts from 'typescript';import assert from 'node:assert/strict';
const compile=p=>ts.transpileModule(fs.readFileSync(p,'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText;
const url=s=>'data:text/javascript;base64,'+Buffer.from(s).toString('base64');
const {classificationMetrics,waitingExperiment}=await import(url(compile('app/research.ts').replaceAll("'./ml'",JSON.stringify(url(compile('app/ml.ts'))))));
const c=classificationMetrics();assert.equal(c.matrix.flat().reduce((a,b)=>a+b,0),24);assert.equal(c.rows.length,12);assert.ok(c.rows.every(r=>r.support===2&&r.f1>=0&&r.f1<=1));
const r=waitingExperiment(),repeat=waitingExperiment();assert.deepEqual(r.weights,repeat.weights);assert.equal(r.training,240);assert.equal(r.testing,60);assert.ok(r.model.mae<r.baseline.mae);assert.ok(r.model.rmse>=r.model.mae);assert.ok(r.model.mae>0);assert.ok(r.predict({ahead:8,duration:12,hour:12,load:.5})>r.predict({ahead:2,duration:12,hour:12,load:.5}));
console.log(JSON.stringify({macroF1:c.macroF1,regression:r.model,baseline:r.baseline,train:r.training,test:r.testing}));
console.log('Research checks passed: confusion-matrix accounting, metric bounds, reproducibility, nonzero held-out error and comparison with baseline. Synthetic results only.');
