import {test} from 'node:test';
import assert from 'node:assert/strict';
import {scoringQuery,scoreCustomer} from './scoring.js';

test('scoring is queried from normalized PostgreSQL VIEW',()=>{
  assert.match(scoringQuery,/FROM public\.v_credit_scoring_normalized/);
  assert.doesNotMatch(scoringQuery,/WITH loan_stats/);
});
test('scoring values normalize output and retain explainable reasons',()=>{
  const result=scoreCustomer({customer_id:1,score:'0.7',raw_score:700,risk:'Низкий',reasons:['Нет просрочек']});
  assert.equal(result.score,0.7);
  assert.equal(result.rawScore,700);
  assert.deepEqual(result.reasons,['Нет просрочек']);
});
test('missing reasons yield empty list',()=>{
  assert.deepEqual(scoreCustomer({score:'0',raw_score:'300'}).reasons,[]);
});
