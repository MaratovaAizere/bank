import {test} from 'node:test';
import assert from 'node:assert/strict';
import {configureTokens,authenticate,can,publicProfile} from './auth.js';

const example={API_TOKEN:'admin-access-token-12345678901234567890',CREDIT_OFFICER_TOKEN:'credit-access-token-123456789012345678',ANALYST_TOKEN:'analyst-access-token-123456789012345678'};
const entries=configureTokens(example);
test('a unique long key is needed for each role',()=>{
  assert.throws(()=>configureTokens({API_TOKEN:'short'}));
  assert.throws(()=>configureTokens({...example,ANALYST_TOKEN:example.API_TOKEN}));
});
test('the server identifies the role from its token, not a user-selected label',()=>{
  for(const [role,key] of [['admin','API_TOKEN'],['credit_officer','CREDIT_OFFICER_TOKEN'],['analyst','ANALYST_TOKEN']]){
    assert.equal(authenticate('Bearer '+example[key],entries),role);
  }
  assert.equal(authenticate('Bearer bad',entries),null);
});
test('only the administrator can manage roles and all tables',()=>{
  assert.equal(can('admin','roles'),true);
  assert.equal(can('admin','write','customers'),true);
  assert.equal(can('credit_officer','roles'),false);
  assert.equal(can('analyst','roles'),false);
});
test('the credit officer can edit loans and payments, but not accounts or employees',()=>{
  assert.equal(can('credit_officer','write','loans'),true);
  assert.equal(can('credit_officer','write','loan_payments'),true);
  assert.equal(can('credit_officer','write','accounts'),false);
  assert.equal(can('credit_officer','read','employees'),false);
  assert.equal(can('credit_officer','scoring'),true);
});
test('the analyst cannot read private banking tables, use scoring or make changes',()=>{
  assert.equal(can('analyst','read','branches'),true);
  assert.equal(can('analyst','read','customers'),false);
  assert.equal(can('analyst','read','accounts'),false);
  assert.equal(can('analyst','scoring'),false);
  assert.equal(can('analyst','refreshReports'),false);
  assert.equal(can('analyst','summary'),true);
  assert.equal(publicProfile('analyst').writeTables.length,0);
});
