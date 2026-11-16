import React,{useEffect,useState} from 'react';
import {Building2,UsersRound,Landmark,WalletCards,TrendingUp,ShieldCheck,BarChart3} from 'lucide-react';

export default function RoleDashboard({role,data,api,onNavigate}){
  const isAnalyst=role.role==='analyst';
  const [summary,setSummary]=useState(null);
  const [error,setError]=useState('');
  useEffect(()=>{
    if(!isAnalyst)return;
    let active=true;
    api('/api/reports/summary').then(value=>{if(active)setSummary(value)})
      .catch(e=>{if(active)setError(e.message)});
    return ()=>{active=false};
  },[isAnalyst,api]);
  const metrics=isAnalyst?[
    {label:'Клиенты банка',value:summary?.customer_count??'—',icon:UsersRound},
    {label:'Банковские счета',value:summary?.account_count??'—',icon:WalletCards},
    {label:'Кредиты',value:summary?.loan_count??'—',icon:Landmark},
    {label:'Филиалы',value:summary?.branch_count??'—',icon:Building2}
  ]:[
    {label:'Клиенты',value:data.customers.length,icon:UsersRound},
    {label:'Кредиты',value:data.loans.length,icon:Landmark},
    {label:'Платежи по кредитам',value:data.loan_payments.length,icon:WalletCards},
    {label:'Счета',value:data.accounts.length,icon:Building2}
  ];
  return <>
    <div className="welcome"><div><div className="eyebrow">NORTHSTAR BANK · РАБОЧЕЕ ПРОСТРАНСТВО</div>
      <h1>{isAnalyst?'Панель аналитика':'Панель кредитного специалиста'}</h1>
      <p>{isAnalyst?'Сводные показатели банка без доступа к персональным данным и изменению записей.':'Кредиты, платежи и оценка кредитного риска клиентов.'}</p>
    </div></div>
    {error&&<p className="rbac-error" role="alert">{error}</p>}
    <div className="metrics">{metrics.map(m=><div className="metric" key={m.label}>
      <div className="metric-icon blue"><m.icon size={21}/></div><div className="metric-label">{m.label}</div>
      <div className="metric-value">{m.value}</div></div>)}</div>
    {isAnalyst&&summary&&<section className="panel rbac-summary">
      <h2>Остатки на счетах в KZT</h2>
      <strong>{new Intl.NumberFormat('ru-RU',{maximumFractionDigits:2}).format(Number(summary.balance_kzt)||0)} ₸</strong>
      <p>Агрегированный показатель. Детали счетов и клиентские данные недоступны роли аналитика.</p>
    </section>}
    <section className="panel rbac-actions">
      <h2>{isAnalyst?'Банковская отчётность':'Рабочие разделы'}</h2>
      <button className="primary" onClick={()=>onNavigate(isAnalyst?'bankAnalytics':'scoring')}>
        {isAnalyst?<BarChart3 size={18}/>:<TrendingUp size={18}/>}
        {isAnalyst?'Открыть отчётность филиалов':'Открыть кредитный скоринг'}
      </button>
      {!isAnalyst&&<button className="outline" onClick={()=>onNavigate('loans')}><Landmark size={18}/> Кредитный портфель</button>}
      <p><ShieldCheck size={16}/> Доступ к операциям ограничен ролью и проверяется сервером.</p>
    </section>
  </>;
}
