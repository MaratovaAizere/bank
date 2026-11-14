import {test,before,after} from 'node:test';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {mappings,translate} from './mapping.js';
const token='test-token-that-is-long-enough-1234';
let child;const port=19000+Math.floor(Math.random()*10000);const base=`http://127.0.0.1:${port}`;
before(async()=>{child=spawn(process.execPath,['server/index.js'],{env:{...process.env,PORT:String(port),HOST:'127.0.0.1',API_TOKEN:token},stdio:['ignore','pipe','pipe']});await Promise.race([once(child.stdout,'data'),once(child,'exit').then(()=>{throw new Error('Server failed to start')})])});
after(async()=>{child.kill('SIGTERM');await once(child,'exit')});
test('enum round trips preserve identifiers and numeric precision',()=>{for(const [table,fields]of Object.entries(mappings))for(const [field,map]of Object.entries(fields))for(const key of Object.keys(map)){const row={[field]:key,amount:'123456789.12',transaction_id:'9007199254740993'};assert.deepEqual(translate(table,translate(table,row),true),row)}});
test('unauthenticated requests rejected',async()=>assert.equal((await fetch(base+'/api/data')).status,401));
test('foreign origin rejected',async()=>assert.equal((await fetch(base+'/api/data',{headers:{Origin:'https://other.example',Authorization:`Bearer ${token}`}})).status,403));
test('local preflight allowed',async()=>{const r=await fetch(base+'/api/data',{method:'OPTIONS',headers:{Origin:'http://localhost:5173'}});assert.equal(r.status,204);assert.equal(r.headers.get('access-control-allow-origin'),'http://localhost:5173')});
test('invalid table, composite key, column, JSON rejected before SQL',async()=>{const headers={Authorization:`Bearer ${token}`,'Content-Type':'application/json'};assert.equal((await fetch(base+'/api/secrets',{method:'POST',headers,body:'{}'})).status,404);assert.equal((await fetch(base+'/api/account_holders/1',{method:'DELETE',headers})).status,400);assert.equal((await fetch(base+'/api/customers',{method:'POST',headers,body:JSON.stringify({evil_column:'x'})})).status,400);assert.equal((await fetch(base+'/api/customers',{method:'POST',headers,body:'{broken'})).status,400)});

test('lecture 9 endpoints require the same API token',async()=>{
 assert.equal((await fetch(base+'/api/lecture9/overview')).status,401);
 assert.equal((await fetch(base+'/api/lecture9/refresh',{method:'POST'})).status,401);
});
test('lecture 9 editing rejects unexpected contact fields before touching DB',async()=>{
 const response=await fetch(base+'/api/lecture9/contacts/1',{method:'PATCH',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify({rolsuper:true})});
 assert.equal(response.status,400);
});
