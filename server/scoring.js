// Educational, explainable scoring using only existing bank records.
export const scoringQuery = `
WITH loan_stats AS (
 SELECT customer_id, COUNT(*)::int AS loan_count,
 COUNT(*) FILTER (WHERE status::text IN ('active','approved'))::int AS open_loans
 FROM public.loans GROUP BY customer_id
), payment_stats AS (
 SELECT l.customer_id, COUNT(*)::int AS payment_count,
 COUNT(*) FILTER (WHERE p.is_late IS TRUE)::int AS late_count
 FROM public.loans l JOIN public.loan_payments p ON p.loan_id=l.loan_id
 GROUP BY l.customer_id
), account_stats AS (
 SELECT ah.customer_id, COUNT(DISTINCT a.account_id)::int AS account_count,
 COALESCE(SUM(CASE WHEN a.currency='KZT' THEN a.balance * ah.ownership_percent / 100.0 ELSE 0 END),0) AS kzt_balance
 FROM public.account_holders ah JOIN public.accounts a ON a.account_id=ah.account_id
 GROUP BY ah.customer_id
)
SELECT c.customer_id, c.first_name, c.last_name,
 COALESCE(ls.loan_count,0) AS loan_count, COALESCE(ls.open_loans,0) AS open_loans,
 COALESCE(ps.payment_count,0) AS payment_count, COALESCE(ps.late_count,0) AS late_count,
 COALESCE(ac.account_count,0) AS account_count, COALESCE(ac.kzt_balance,0) AS kzt_balance
FROM public.customers c
LEFT JOIN loan_stats ls ON ls.customer_id=c.customer_id
LEFT JOIN payment_stats ps ON ps.customer_id=c.customer_id
LEFT JOIN account_stats ac ON ac.customer_id=c.customer_id
ORDER BY c.customer_id`;

export function scoreCustomer(row) {
  const loans = Number(row.loan_count);
  const late = Number(row.late_count);
  const payments = Number(row.payment_count);
  const accounts = Number(row.account_count);
  const balance = Number(row.kzt_balance);
  const open = Number(row.open_loans);

  let score = 550;
  const reasons = [];

  if (payments > 0) {
    const adjustment = late === 0
      ? 110
      : -Math.min(220, Math.round(late / payments * 220));

    score += adjustment;

    reasons.push(
      late === 0
        ? 'Платежи без просрочек'
        : `${late} просрочек из ${payments} платежей`
    );
  } else {
    reasons.push('Нет истории платежей');
  }

  if (loans > 0) {
    score += 30;
    reasons.push('Есть кредитная история');
  }

  if (accounts > 0) {
    score += 35;
    reasons.push('Есть банковский счёт');
  }

  if (balance >= 1000000) {
    score += 65;
    reasons.push('Баланс KZT от 1 млн');
  } else if (balance >= 100000) {
    score += 30;
    reasons.push('Баланс KZT от 100 тыс.');
  }

  if (open > 2) {
    score -= 50;
    reasons.push('Более двух открытых кредитов');
  }

  // Limit the original score to 300–850
  score = Math.max(300, Math.min(850, score));

  // Determine risk using the original score
  const risk = score >= 700
    ? 'Низкий'
    : score >= 580
      ? 'Средний'
      : 'Высокий';

  // Normalize the score to the range 0–1
  const normalizedScore = (score - 300) / (850 - 300);

  return {
    ...row,
    score: Number(normalizedScore.toFixed(1)),
    rawScore: score,
    risk,
    reasons
  };
}

