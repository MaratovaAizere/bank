// All credit metrics and rules are computed in PostgreSQL views.
// The API reads one compact, explainable result per customer; no CTE is
// assembled in JavaScript and no second round of scoring is performed here.
export const scoringQuery = `
  SELECT customer_id, first_name, last_name,
         loan_count, open_loans, payment_count, late_count,
         account_count, kzt_balance,
         score, risk, reasons, raw_score
  FROM public.v_credit_scoring_normalized
  ORDER BY customer_id`;

export function scoreCustomer(row) {
  // PostgreSQL NUMERIC values may be returned as strings by node-postgres.
  return {
    ...row,
    score: Number(row.score),
    rawScore: Number(row.raw_score),
    reasons: Array.isArray(row.reasons) ? row.reasons : [],
  };
}
