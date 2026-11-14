import React, {useEffect, useState} from 'react';
import {Database, Layers3, RefreshCcw, ShieldCheck, Pencil, X, Check, AlertCircle, Building2} from 'lucide-react';

const formatRoleGroups = value => {
  if (Array.isArray(value)) return value.join(', ') || '—';
  if (typeof value === 'string') return value.replace(/^\{|\}$/g, '').replace(/"/g, '') || '—';
  return '—';
};
const formatMoney = value => new Intl.NumberFormat('ru-RU', {maximumFractionDigits:2}).format(Number(value) || 0) + ' ₸';
const emptyRow = (cols, label='Нет данных') => <tr><td className="analytics-empty" colSpan={cols}>{label}</td></tr>;
const sections = [
  {key:'views',title:'Клиенты и счета',caption:'Сводные данные по клиентам',icon:Layers3},
  {key:'branches',title:'Филиальная сеть',caption:'Показатели филиалов',icon:Building2},
  {key:'roles',title:'Роли и доступ',caption:'Права пользователей базы',icon:ShieldCheck}
];

export default function BankAnalyticsPage({api, notify}) {
  const [section,setSection]=useState('views');
  const [view,setView]=useState('accounts');
  const [analytics,setAnalytics]=useState(null);
  const [analyticsLoading,setAnalyticsLoading]=useState(true);
  const [analyticsError,setAnalyticsError]=useState('');
  const [roles,setRoles]=useState([]);
  const [rolesLoading,setRolesLoading]=useState(false);
  const [rolesError,setRolesError]=useState('');
  const [rolesLoaded,setRolesLoaded]=useState(false);
  const [refreshing,setRefreshing]=useState(false);
  const [editing,setEditing]=useState(null);
  const [saving,setSaving]=useState(false);

  const loadAnalytics = async () => {
    setAnalyticsLoading(true);
    setAnalyticsError('');
    try { setAnalytics(await api('/api/bank-analytics/overview')); }
    catch(e) { setAnalyticsError(e.message); }
    finally { setAnalyticsLoading(false); }
  };
  const loadRoles = async () => {
    setRolesLoading(true);
    setRolesError('');
    try {
      const data=await api('/api/bank-access/roles');
      setRoles(Array.isArray(data?.roles) ? data.roles : []);
      setRolesLoaded(true);
    } catch(e) {setRolesError(e.message);}
    finally {setRolesLoading(false);}
  };
  useEffect(()=>{void loadAnalytics();},[]);
  useEffect(()=>{if(section==='roles'&&!rolesLoaded){void loadRoles();}},[section,rolesLoaded]);

  const refreshBranches = async () => {
    setRefreshing(true);setAnalyticsError('');
    try {
      await api('/api/bank-analytics/refresh',{method:'POST'});
      await loadAnalytics();
      notify('Статистика филиалов обновлена');
    } catch(e) {setAnalyticsError(e.message);notify(e.message);}
    finally {setRefreshing(false);}
  };
  const saveContact = async event => {
    event.preventDefault();
    if(!editing)return;
    setSaving(true);
    try {
      await api(`/api/bank-analytics/contacts/${editing.customer_id}`,{
        method:'PATCH',body:JSON.stringify({email:editing.email,phone:editing.phone})
      });
      setEditing(null);
      await loadAnalytics();
      notify('Контактные данные сохранены');
    } catch(e) {notify(e.message);}
    finally {setSaving(false);}
  };
  const blocked = !analyticsLoading && (!analytics?.ready || !!analyticsError);

  return <div className="analytics-page">
    <div className="welcome analytics-welcome">
      <div>
        <div className="eyebrow">БАНКОВСКАЯ АНАЛИТИКА</div>
        <h1>Аналитика и управление доступом</h1>
        <p>Сводные показатели по клиентам, кредитам, филиалам и пользователям системы.</p>
      </div>
    </div>
    <div className="analytics-sections" role="tablist" aria-label="Разделы аналитики">
      {sections.map(item=><button
        key={item.key} id={`analytics-tab-${item.key}`} type="button"
        role="tab" aria-selected={section===item.key}
        aria-controls={`analytics-panel-${item.key}`}
        className={`analytics-section ${section===item.key?'selected':''}`}
        onClick={()=>setSection(item.key)}>
        <span className="analytics-section-icon"><item.icon size={21}/></span>
        <span><strong>{item.title}</strong><small>{item.caption}</small></span>
      </button>)}
    </div>

    {section==='roles' ? <div role="tabpanel" id="analytics-panel-roles" aria-labelledby="analytics-tab-roles">
      <section className="panel analytics-info">
        <div className="analytics-label"><ShieldCheck size={18}/> КОНТРОЛЬ ДОСТУПА</div>
        <div className="analytics-info-row">
          <div><h2>Роли и полномочия</h2><p>Список ролей PostgreSQL, их разрешений и членства в группах. Данные доступны только для просмотра.</p></div>
          <button type="button" className="outline analytics-icon-button" disabled={rolesLoading} onClick={loadRoles}><RefreshCcw size={16}/>{rolesLoading?'Обновление…':'Обновить'}</button>
        </div>
      </section>
      {rolesError&&<div className="analytics-warning"><AlertCircle size={17}/>{rolesError}<button className="outline" type="button" onClick={loadRoles}>Повторить</button></div>}
      <section className="panel analytics-table-panel">
        <div className="analytics-table-heading"><h2>Реестр ролей</h2><span className="count-pill">{roles.length} записей</span></div>
        <div className="table-scroll"><table><thead><tr><th>Роль</th><th>Вход</th><th>Администратор</th><th>Создание БД</th><th>Управление ролями</th><th>Репликация</th><th>Группы</th></tr></thead><tbody>
          {roles.map(item=><tr key={item.rolname}>
            <td className="num">{item.rolname}</td>
            <td>{item.rolcanlogin?'Разрешён':'Запрещён'}</td>
            <td>{item.rolsuper?'Да':'Нет'}</td>
            <td>{item.rolcreatedb?'Да':'Нет'}</td>
            <td>{item.rolcreaterole?'Да':'Нет'}</td>
            <td>{item.rolreplication?'Да':'Нет'}</td>
            <td>{formatRoleGroups(item.member_of)}</td>
          </tr>)}
          {rolesLoading&&emptyRow(7,'Загружаем данные о ролях…')}
          {!rolesLoading&&!roles.length&&emptyRow(7,rolesError?'Не удалось получить роли':'Нет доступных записей')}
        </tbody></table></div>
      </section>
      <p className="hint"><ShieldCheck size={16}/> Изменение полномочий выполняется администратором базы данных.</p>
    </div> : <div role="tabpanel" id={`analytics-panel-${section}`} aria-labelledby={`analytics-tab-${section}`}>
      {analyticsLoading&&<section className="panel analytics-message">Загружаем банковские показатели…</section>}
      {blocked&&<section className="panel analytics-message">
        <div className="analytics-label"><AlertCircle size={18}/> АНАЛИТИКА НЕДОСТУПНА</div>
        <h2>Данные отчётности пока не готовы</h2>
        <p>{analyticsError || 'Необходимо настроить аналитические представления базы данных. Раздел «Роли и доступ» работает независимо.'}</p>
        <button type="button" className="outline analytics-icon-button" onClick={loadAnalytics}><RefreshCcw size={16}/> Проверить ещё раз</button>
      </section>}
      {!analyticsLoading&&analytics?.ready&&!analyticsError&&<>
        {section==='views'&&<>
          <section className="panel analytics-info">
            <div className="analytics-label"><Layers3 size={18}/> КЛИЕНТСКИЙ ПОРТФЕЛЬ</div>
            <h2>Клиенты, счета и кредитные продукты</h2>
            <p>Актуальные сведения из банковской базы, включая количество счетов, остатки и действующие кредиты.</p>
            <div className="analytics-filter">
              <button type="button" className={view==='accounts'?'chosen':''} onClick={()=>setView('accounts')}>Клиенты и счета</button>
              <button type="button" className={view==='loans'?'chosen':''} onClick={()=>setView('loans')}>Действующие кредиты</button>
              <button type="button" className={view==='contacts'?'chosen':''} onClick={()=>setView('contacts')}>Контактные данные</button>
            </div>
          </section>
          <section className="panel analytics-table-panel">
            <div className="analytics-table-heading"><h2>{view==='accounts'?'Счета клиентов':view==='loans'?'Кредитный портфель':'Контакты клиентов'}</h2>
              <span className="count-pill">{view==='accounts'?analytics.customers.length:view==='loans'?analytics.loans.length:analytics.contacts.length} записей</span>
            </div>
            <div className="table-scroll">
              {view==='accounts'&&<table><thead><tr><th>ID</th><th>Клиент</th><th>Счета</th><th>Баланс KZT</th></tr></thead><tbody>
                {analytics.customers.map(item=><tr key={item.customer_id}><td>#{item.customer_id}</td><td>{item.first_name} {item.last_name}</td><td>{item.account_count}</td><td className="num">{formatMoney(item.balance_kzt)}</td></tr>)}
                {!analytics.customers.length&&emptyRow(4)}
              </tbody></table>}
              {view==='loans'&&<table><thead><tr><th>ID кредита</th><th>Клиент</th><th>Сумма</th><th>Ставка</th><th>Статус</th></tr></thead><tbody>
                {analytics.loans.map(item=><tr key={item.loan_id}><td>#{item.loan_id}</td><td>{item.first_name} {item.last_name}</td><td className="num">{formatMoney(item.principal_amount)}</td><td>{item.interest_rate}%</td><td>{item.status}</td></tr>)}
                {!analytics.loans.length&&emptyRow(5,'Действующих кредитов нет')}
              </tbody></table>}
              {view==='contacts'&&<table><thead><tr><th>ID</th><th>Клиент</th><th>Телефон</th><th>Email</th><th>Действие</th></tr></thead><tbody>
                {analytics.contacts.map(item=><tr key={item.customer_id}><td>#{item.customer_id}</td><td>{item.first_name} {item.last_name}</td><td>{item.phone||'—'}</td><td>{item.email||'—'}</td><td><button className="outline analytics-icon-button" type="button" onClick={()=>setEditing({...item,phone:item.phone??'',email:item.email??''})}><Pencil size={14}/> Изменить</button></td></tr>)}
                {!analytics.contacts.length&&emptyRow(5)}
              </tbody></table>}
            </div>
          </section>
        </>}
        {section==='branches'&&<>
          <section className="panel analytics-info">
            <div className="analytics-label"><Database size={18}/> ФИЛИАЛЬНАЯ СЕТЬ</div>
            <div className="analytics-info-row"><div><h2>Операционные показатели филиалов</h2>
              <p>Количество счетов и кредитов, а также суммарные остатки в тенге. Показатели обновляются по запросу.</p></div>
              <button type="button" className="primary analytics-icon-button" disabled={refreshing} onClick={refreshBranches}><RefreshCcw size={16}/>{refreshing?'Обновление…':'Обновить показатели'}</button>
            </div>
          </section>
          <section className="panel analytics-table-panel">
            <div className="analytics-table-heading"><h2>Результаты по филиалам</h2><span className="count-pill">{analytics.branches.length} филиалов</span></div>
            <div className="table-scroll"><table><thead><tr><th>ID</th><th>Филиал</th><th>Город</th><th>Счета</th><th>Кредиты</th><th>Баланс KZT</th></tr></thead><tbody>
              {analytics.branches.map(item=><tr key={item.branch_id}><td>#{item.branch_id}</td><td>{item.branch_name}</td><td>{item.city}</td><td>{item.account_count}</td><td>{item.loan_count}</td><td className="num">{formatMoney(item.total_kzt)}</td></tr>)}
              {!analytics.branches.length&&emptyRow(6,'Пока нет данных о филиалах')}
            </tbody></table></div>
          </section>
        </>}
      </>}
    </div>}
    {editing&&<div className="modal-backdrop" onMouseDown={e=>{if(e.target===e.currentTarget)setEditing(null)}}>
      <div className="modal" role="dialog" aria-modal="true" aria-label="Контактные данные клиента">
        <div className="modal-head"><h2>Контактные данные</h2><button className="close" type="button" onClick={()=>setEditing(null)}><X size={20}/></button></div>
        <form onSubmit={saveContact}><div className="analytics-edit-body">
          <strong>{editing.first_name} {editing.last_name} (#{editing.customer_id})</strong>
          <label>Телефон<input value={editing.phone} onChange={e=>setEditing({...editing,phone:e.target.value})} maxLength={255}/></label>
          <label>Email<input type="email" value={editing.email} onChange={e=>setEditing({...editing,email:e.target.value})} maxLength={255}/></label>
        </div><div className="modal-footer"><button type="button" className="outline" onClick={()=>setEditing(null)}>Отмена</button><button className="primary" type="submit" disabled={saving}><Check size={16}/>{saving?'Сохранение…':'Сохранить'}</button></div></form>
      </div>
    </div>}
  </div>;
}
