// Demo RBAC: individual role keys checked on every API route.
// Tokens are server-side secrets in .env. Never expose them in client bundles.
import {timingSafeEqual} from 'node:crypto';
import {schema} from '../src/data.js';

const allTables = Object.keys(schema);
export const roles = Object.freeze({
  admin: {
    label:'Администратор',
    readTables:allTables,
    writeTables:allTables,
    scoring:true, analytics:true, roles:true, contactEdit:true, refreshReports:true, summary:true
  },
  credit_officer: {
    label:'Кредитный специалист',
    readTables:['customers','accounts','account_holders','branches','loans','loan_payments'],
    writeTables:['loans','loan_payments'],
    scoring:true, analytics:false, roles:false, contactEdit:false, refreshReports:false, summary:false
  },
  analyst: {
    label:'Аналитик',
    readTables:['branches'],
    writeTables:[],
    scoring:false, analytics:true, roles:false, contactEdit:false, refreshReports:false, summary:true
  }
});

const tokenKeys={admin:'API_TOKEN',credit_officer:'CREDIT_OFFICER_TOKEN',analyst:'ANALYST_TOKEN'};
export function configureTokens(env=process.env){
  const entries=Object.entries(tokenKeys).filter(([,key])=>env[key]).map(([role,key])=>[role,String(env[key])]);
  if(!env.API_TOKEN || String(env.API_TOKEN).length<24) throw new Error('Set API_TOKEN to a random value of at least 24 characters in .env');
  for(const [role,token] of entries) if(token.length<24) throw new Error(`Token for ${role} must be at least 24 characters`);
  if(new Set(entries.map(([,token])=>token)).size!==entries.length) throw new Error('Every role must have a different token');
  return entries;
}
export function authenticate(authorization,entries){
  const supplied=Buffer.from(String(authorization||''));
  for(const [role,token] of entries){
    const expected=Buffer.from('Bearer '+token);
    if(supplied.length===expected.length && timingSafeEqual(supplied,expected))return role;
  }
  return null;
}
export function can(role,ability,table){
  const r=roles[role];
  if(!r)return false;
  if(ability==='read')return r.readTables.includes(table);
  if(ability==='write')return r.writeTables.includes(table);
  return r[ability]===true;
}
export function publicProfile(role){
  const r=roles[role];
  return {role,label:r.label,readTables:r.readTables,writeTables:r.writeTables,
    scoring:r.scoring,analytics:r.analytics,roles:r.roles,refreshReports:r.refreshReports};
}
