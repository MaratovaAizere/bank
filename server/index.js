import http from 'node:http';
import {readFile} from 'node:fs/promises';
import pg from 'pg';
import {schema,primaryKey} from '../src/data.js';
import {translate} from './mapping.js';
import {scoringQuery,scoreCustomer} from './scoring.js';
import {configureTokens,authenticate,can,publicProfile,roles as appRoles} from './auth.js';
const columns=JSON.parse(await readFile(new URL('./columns.json',import.meta.url),'utf8'));
// Preserve dates, numeric precision, and bigint identifiers in JSON.
pg.types.setTypeParser(1082,v=>v);
pg.types.setTypeParser(1114,v=>v.replace(' ','T'));
const configuredTokens=configureTokens();
const pool=new pg.Pool({connectionString:process.env.DATABASE_URL,connectionTimeoutMillis:5000,max:5,statement_timeout:10000});
pool.on('error',e=>console.error('Database connection error:',e.code));
const allowed=new Set((process.env.FRONTEND_ORIGINS||'http://localhost:5173,http://127.0.0.1:5173').split(',').map(s=>s.trim()));
const quote=s=>'"'+s+'"';
const errors={'23505':'Такая запись уже существует.','23503':'Связанная запись отсутствует или используется другой таблицей.','23502':'Заполните обязательные поля.','23514':'Данные нарушают ограничения базы (сумма, дата или значение).','22P02':'Неверный формат значения.','22007':'Неверный формат даты.','22008':'Неверная дата.','22003':'Число слишком большое.','22001':'Текст слишком длинный.', 'P0002':'Счёт не найден.', 'P0001':'Операция отклонена.'};
function fail(status,message){throw Object.assign(new Error(message),{status})}
async function bodyOf(req){let body='';for await(const chunk of req){body+=chunk;if(Buffer.byteLength(body)>65536)fail(413,'Слишком большой запрос.')}try{return JSON.parse(body)}catch{fail(400,'Некорректный JSON.')}}
const server=http.createServer(async(req,res)=>{
 const send=(code,value)=>{res.writeHead(code,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'});res.end(JSON.stringify(value))};
 try{
  const origin=req.headers.origin;if(origin&&!allowed.has(origin))return send(403,{error:'Этот адрес фронтенда не разрешён в FRONTEND_ORIGINS.'});
  if(origin){res.setHeader('Access-Control-Allow-Origin',origin);res.setHeader('Vary','Origin')}
  res.setHeader('Access-Control-Allow-Headers','Authorization, Content-Type');res.setHeader('Access-Control-Allow-Methods','GET, POST, PATCH, DELETE, OPTIONS');
  if(req.method==='OPTIONS'){res.writeHead(204);return res.end()}
  const url=new URL(req.url,'http://localhost');
  if(url.pathname==='/health'&&req.method==='GET')return send(200,{status:'running'});
  const role=authenticate(req.headers.authorization,configuredTokens);
  if(!role)return send(401,{error:'Неверный ключ доступа.'});
  const requireRight=(ability,table)=>{if(!can(role,ability,table))fail(403,'Недостаточно прав для этой операции.')};
  if(url.pathname==='/api/auth/me'&&req.method==='GET')return send(200,publicProfile(role));
  if(url.pathname==='/api/auth/roles'&&req.method==='GET'){
   requireRight('roles');
   return send(200,{roles:Object.entries(appRoles).map(([name,r])=>({
     name,label:r.label,enabled:configuredTokens.some(([active])=>active===name),
     readTables:r.readTables,writeTables:r.writeTables,
     scoring:r.scoring,analytics:r.analytics,roles:r.roles
   }))});
  }
  // Banking reports use fixed queries; browsers cannot execute arbitrary SQL.
  // Role data is independent of reports so access management still opens
  // when the reporting views have not been initialized.
  if(url.pathname==='/api/bank-access/roles'&&req.method==='GET'){
   requireRight('roles');
   const result=await pool.query(`
    SELECT r.rolname, r.rolcanlogin, r.rolsuper, r.rolcreatedb,
           r.rolcreaterole, r.rolreplication,
           COALESCE((SELECT array_agg(parent.rolname::text ORDER BY parent.rolname)
            FROM pg_auth_members m JOIN pg_roles parent ON parent.oid=m.roleid
            WHERE m.member=r.oid),ARRAY[]::text[]) AS member_of
    FROM pg_roles r WHERE r.rolname NOT LIKE 'pg_%' ORDER BY r.rolname LIMIT 100`);
   return send(200,{roles:result.rows});
  }
  if(['/api/bank-analytics/overview','/api/lecture9/overview'].includes(url.pathname)&&req.method==='GET'){
   requireRight('analytics');
   if(role==='analyst'){
    const branchObject=await pool.query("SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='mv_branch_statistics' AND c.relkind='m'");
    if(!branchObject.rowCount)return send(200,{ready:false,missing:['mv_branch_statistics'],roles:[],customers:[],loans:[],branches:[],contacts:[]});
    const branchData=await pool.query('SELECT * FROM public.mv_branch_statistics ORDER BY branch_id LIMIT 200');
    return send(200,{ready:true,missing:[],roles:[],customers:[],loans:[],branches:branchData.rows,contacts:[]});
   }
   const roles=await pool.query(`
    SELECT r.rolname, r.rolcanlogin, r.rolsuper, r.rolcreatedb,
           r.rolcreaterole, r.rolreplication,
           COALESCE((SELECT array_agg(parent.rolname::text ORDER BY parent.rolname)
            FROM pg_auth_members m JOIN pg_roles parent ON parent.oid=m.roleid
            WHERE m.member=r.oid),ARRAY[]::text[]) AS member_of
    FROM pg_roles r WHERE r.rolname NOT LIKE 'pg_%' ORDER BY r.rolname LIMIT 100`);
   const required=['v_customer_accounts','v_active_loans','v_customer_contacts_editable','v_customers_with_email','mv_branch_statistics'];
   const objects=await pool.query(`
    SELECT c.relname
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relname=ANY($1::text[])
      AND c.relkind IN ('v','m')`,[required]);
   const found=new Set(objects.rows.map(r=>r.relname));
   const missing=required.filter(n=>!found.has(n));
   if(missing.length)return send(200,{ready:false,missing,roles:roles.rows,customers:[],loans:[],branches:[],contacts:[]});
   const [customers,loans,branches,contacts]=await Promise.all([
    pool.query('SELECT * FROM public.v_customer_accounts ORDER BY customer_id LIMIT 200'),
    pool.query('SELECT * FROM public.v_active_loans ORDER BY loan_id LIMIT 200'),
    pool.query('SELECT * FROM public.mv_branch_statistics ORDER BY branch_id LIMIT 200'),
    pool.query('SELECT * FROM public.v_customer_contacts_editable ORDER BY customer_id LIMIT 200')
   ]);
   return send(200,{ready:true,missing:[],roles:roles.rows,customers:customers.rows,loans:loans.rows,branches:branches.rows,contacts:contacts.rows});
  }
  if(['/api/bank-analytics/refresh','/api/lecture9/refresh'].includes(url.pathname)&&req.method==='POST'){
   requireRight('refreshReports');
   await pool.query('REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_branch_statistics');
   return send(200,{ok:true,message:'Материализованное представление обновлено.'});
  }
  const contactMatch=url.pathname.match(/^\/api\/(?:bank-analytics|lecture9)\/contacts\/(\d+)$/);
  if(contactMatch&&req.method==='PATCH'){
   requireRight('contactEdit');
   const input=await bodyOf(req);
   if(!input||typeof input!=='object'||Array.isArray(input))fail(400,'Ожидается объект JSON.');
   const fields=Object.keys(input);
   if(!fields.length||fields.some(key=>!['email','phone'].includes(key)))fail(400,'Разрешено изменять только email и телефон.');
   for(const key of fields){
    if(input[key]!==null&&(typeof input[key]!=='string'||input[key].length>255))fail(400,'Неверное значение поля '+key);
   }
   const sets=fields.map((key,i)=>`"${key}"=$${i+1}`).join(', ');
   const updated=await pool.query(`UPDATE public.v_customer_contacts_editable SET ${sets} WHERE customer_id=$${fields.length+1} RETURNING *`,[...fields.map(key=>input[key]),contactMatch[1]]);
   if(!updated.rowCount)fail(404,'Клиент не найден.');
   return send(200,updated.rows[0]);
  }
  if(url.pathname==='/api/credit-scoring'&&req.method==='GET'){
   requireRight('scoring');
   const result=await pool.query(scoringQuery);return send(200,result.rows.map(scoreCustomer));
  }
  if(url.pathname==='/api/reports/summary'&&req.method==='GET'){
   requireRight('summary');
   const metrics=await pool.query('SELECT * FROM public.v_bank_summary');
   return send(200,metrics.rows[0]);
  }
  if(url.pathname==='/api/data'&&req.method==='GET'){
   const client=await pool.connect();try{
    await client.query('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY');
    const data={};
    for(const table of Object.keys(schema)){
     if(!can(role,'read',table)){data[table]=[];continue;}
     const keys=primaryKey(table)?[primaryKey(table)]:['account_id','customer_id'];
     const source=table==='transactions'?'v_transaction_balances':table;
     const result=await client.query(`SELECT * FROM public.${quote(source)} ORDER BY ${keys.map(quote).join(',')}`);
     data[table]=result.rows.map(row=>translate(table,row));
    }
    await client.query('COMMIT');return send(200,data)
   }catch(e){await client.query('ROLLBACK');throw e}finally{client.release()}
  }
  const match=url.pathname.match(/^\/api\/([a-z_]+)(?:\/([^/]+))?$/);if(!match||!Object.hasOwn(schema,match[1]))return send(404,{error:'Unknown endpoint'});
  const [,table,rawKey]=match;requireRight('write',table);const pk=primaryKey(table);const keys=pk?[pk]:['account_id','customer_id'];const keyValues=rawKey?decodeURIComponent(rawKey).split(':'):[];
  if(rawKey&&(keyValues.length!==keys.length||keyValues.some(v=>!/^\d+$/.test(v))))fail(400,'Неверный ID.');
  if(!['POST','PATCH','DELETE'].includes(req.method)||((req.method==='POST')===Boolean(rawKey)))return send(405,{error:'Method not allowed'});
  let fields=[],values=[];
  if(req.method!=='DELETE'){
   const input=await bodyOf(req);if(!input||Array.isArray(input)||typeof input!=='object')fail(400,'Ожидается объект JSON.');
   const row=translate(table,input,true);
   for(const [key,value]of Object.entries(row)){
    if(!Object.hasOwn(columns[table],key)||key===pk)fail(400,'Недопустимое поле: '+key);
    if(table==='accounts'&&key==='balance')fail(400,'Баланс можно изменять только через транзакции.');
    if(value!==null&&!['string','number','boolean'].includes(typeof value))fail(400,'Неверный формат поля: '+key);
    if(req.method==='POST'&&(value===''||value==null)&&columns[table][key].default)continue;
    fields.push(key);values.push(value===''?null:value);
   }
   if(!fields.length)fail(400,'Нет полей для сохранения.');
  }
  const where=keys.map((key,i)=>`${quote(key)}=$${values.length+i+1}`).join(' AND ');
  let query;
  if(req.method==='POST')query=`INSERT INTO public.${quote(table)} (${fields.map(quote)}) VALUES (${values.map((_,i)=>'$'+(i+1))}) RETURNING *`;
  else if(req.method==='PATCH')query=`UPDATE public.${quote(table)} SET ${fields.map((key,i)=>`${quote(key)}=$${i+1}`).join(',')} WHERE ${where} RETURNING *`;
  else query=`DELETE FROM public.${quote(table)} WHERE ${where} RETURNING *`;
  let result;
  if(table==='transactions'){
   // The trigger and its account updates are committed or rolled back together.
   const client=await pool.connect();
   try{
    await client.query('BEGIN');
    result=await client.query(query,[...values,...keyValues]);
    if(!result.rowCount)fail(404,'Запись не найдена. Обновите таблицу.');
    await client.query('COMMIT');
   }catch(error){await client.query('ROLLBACK');throw error}
   finally{client.release()}
  }else result=await pool.query(query,[...values,...keyValues]);
  if(!result.rowCount)fail(404,'Запись не найдена. Обновите таблицу.');
  return send(req.method==='POST'?201:200,translate(table,result.rows[0]));
 }catch(e){console.error('Request failed:',e.code||e.status||'internal');return send(e.status||(errors[e.code]?400:503),{error:e.status?e.message:e.code==='P0001'?e.message:errors[e.code]||'База недоступна. Проверьте настройки PostgreSQL на сервере.'})}
});
server.listen(Number(process.env.PORT||3001),process.env.HOST||'127.0.0.1',()=>console.log('Bank API listening on port '+(process.env.PORT||3001)));
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>server.close(()=>pool.end().then(()=>process.exit(0))));