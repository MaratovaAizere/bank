#!/usr/bin/env python3
"""Enable the same page selector (10/25/50/100) across Northstar Bank tables.
Run from the project root. Does not change the database, API, or .env.
"""
from pathlib import Path
import re
import shutil
import sys
from datetime import datetime

root = Path.cwd()
main_file = root / 'src' / 'main.jsx'
analytics_file = root / 'src' / 'BankAnalyticsPage.jsx'
style_file = root / 'src' / 'style.css'
component_file = root / 'src' / 'BankPagination.jsx'
if not (root / 'package.json').exists() or not all(p.is_file() for p in [main_file, analytics_file, style_file]):
    sys.exit('Ошибка: запусти скрипт в папке проекта (package.json, src/main.jsx, src/BankAnalyticsPage.jsx).')

main = main_file.read_text(encoding='utf-8')
analytics = analytics_file.read_text(encoding='utf-8')
styles = style_file.read_text(encoding='utf-8')
if "import BankPagination from './BankPagination.jsx';" in main:
    print('Пагинация уже установлена. Повторять не нужно.')
    sys.exit(0)

def once(text, old, new, what):
    count = text.count(old)
    if count != 1:
        raise ValueError(f'{what}: ожидалось 1 совпадение, найдено {count}. Ничего не изменено.')
    return text.replace(old, new, 1)

try:
    # One shared component, used by each of the existing data tables.
    main = once(main, "import './style.css';", "import BankPagination from './BankPagination.jsx';\nimport './style.css';", 'Импорт в main.jsx')
    analytics = once(analytics, "import React, {useEffect, useState} from 'react';", "import React, {useEffect, useState} from 'react';\nimport BankPagination from './BankPagination.jsx';", 'Импорт в BankAnalyticsPage.jsx')

    # Each standard data section remembers its own page-size choice (default: 25).
    if '[transactionPageSize,setTransactionPageSize]=useState(25),' in main:
        main = once(main, '[transactionPageSize,setTransactionPageSize]=useState(25),', '[pageSizes,setPageSizes]=useState({}),', 'Состояние размеров страниц')
        main = once(main,
            "const pageSize=entity==='transactions'?transactionPageSize:8;",
            "const pageSize=pageSizes[entity]??25;",
            'Размер страницы в таблицах')
    else:
        main = once(main, '[pageNum,setPageNum]=useState(1),', '[pageNum,setPageNum]=useState(1),[pageSizes,setPageSizes]=useState({}),', 'Состояние размеров страниц')
        oldcalc='const totalPages=Math.max(1,Math.ceil(filtered.length/8)),current=Math.min(pageNum,totalPages),rows=filtered.slice((current-1)*8,current*8);'
        newcalc='const pageSize=pageSizes[entity]??25;const totalPages=Math.max(1,Math.ceil(filtered.length/pageSize)),current=Math.max(1,Math.min(pageNum,totalPages)),rows=filtered.slice((current-1)*pageSize,current*pageSize);'
        main=once(main,oldcalc,newcalc,'Пагинация стандартных таблиц')

    # Sort transactions newest first when no explicit header sort is selected.
    if "if(entity==='transactions'&&!sort)" not in main:
        injection="""if(entity==='transactions'&&!sort){filtered=[...filtered].sort((a,b)=>{
 const ai=Number(a.transaction_id),bi=Number(b.transaction_id);
 return Number.isFinite(ai)&&Number.isFinite(bi)?bi-ai:String(b.transaction_date??'').localeCompare(String(a.transaction_date??''));
})}\n"""
        marker='const pageSize=pageSizes[entity]??25;'
        main=once(main,marker,injection+marker,'Сортировка транзакций')

    # Replace only the existing standard-table footer, regardless of whether
    # the earlier transaction-only paginator is installed.
    table_start = main.index('const renderTable=')
    footer_start = main.index('<div className="table-footer">', table_start)
    footer_end = main.index('</section><div className="hint">', footer_start)
    old_footer = main[footer_start:footer_end]
    if 'Показано' not in old_footer or 'totalPages' not in old_footer:
        raise ValueError('Неизвестная разметка стандартной пагинации.')
    new_footer = """<BankPagination total={filtered.length} page={current} pageSize={pageSize}
  onPageChange={setPageNum}
  onPageSizeChange={size=>{setPageSizes(prev=>({...prev,[entity]:size}));setPageNum(1)}} />"""
    main=main[:footer_start]+new_footer+main[footer_end:]

    # The scoring page is a separate table and uses the same common paginator.
    score_start=main.index('const renderScoring=')
    score_end=main.index('const renderTable=',score_start)
    score_block=main[score_start:score_end]
    replaced,n=re.subn(r'const renderScoring=\(\)=>\s*<>',
        "const renderScoring=()=>{const pageSize=pageSizes.scoring??25;const totalPages=Math.max(1,Math.ceil(scores.length/pageSize));const current=Math.max(1,Math.min(pageNum,totalPages));return <>",
        score_block,count=1)
    if n!=1:
        raise ValueError('Не удалось найти начало таблицы скоринга.')
    score_block=replaced
    score_block=once(score_block,'{scores.map(r=>','{scores.slice((current-1)*pageSize,current*pageSize).map(r=>','Строки скоринга')
    score_block=once(score_block,"</table></div></section><div className='hint'>",
        "</table></div><BankPagination total={scores.length} page={current} pageSize={pageSize} onPageChange={setPageNum} onPageSizeChange={size=>{setPageSizes(prev=>({...prev,scoring:size}));setPageNum(1)}} /></section><div className='hint'>",
        'Панель страниц скоринга')
    # Arrow expression converted to a block requires an extra closing brace.
    ending=score_block.rstrip()
    if not ending.endswith('</>;'):
        raise ValueError('Неизвестное завершение renderScoring().')
    score_block=ending[:-4]+'</>;};\n'
    main=main[:score_start]+score_block+main[score_end:]

    # Analytics sections (customer views, loan views, contacts, branches, roles).
    after="""
  const [pageByKey, setPageByKey] = useState({});
  const [pageSizeByKey, setPageSizeByKey] = useState({});
  const getCurrentPage=(rows,key)=>{
    const size=pageSizeByKey[key]??25;
    return Math.max(1,Math.min(pageByKey[key]??1,Math.max(1,Math.ceil(rows.length/size))));
  };
  const pageRows=(rows,key)=>{
    const size=pageSizeByKey[key]??25;
    const current=getCurrentPage(rows,key);
    return rows.slice((current-1)*size,current*size);
  };
  const pager=(rows,key)=><BankPagination
    total={rows.length} page={getCurrentPage(rows,key)} pageSize={pageSizeByKey[key]??25}
    onPageChange={page=>setPageByKey(prev=>({...prev,[key]:page}))}
    onPageSizeChange={size=>{setPageSizeByKey(prev=>({...prev,[key]:size}));setPageByKey(prev=>({...prev,[key]:1}));}}
  />;
"""
    analytics=once(analytics,'  const [saving,setSaving]=useState(false);',
        '  const [saving,setSaving]=useState(false);'+after,'Состояние пагинации аналитики')
    for source,key in [('bankRoles','bankRoles'),('roles','postgresRoles'),
                       ('analytics.customers','views:accounts'),('analytics.loans','views:loans'),
                       ('analytics.contacts','views:contacts'),('analytics.branches','branches')]:
        analytics=once(analytics,'{'+source+'.map(item=>',"{pageRows("+source+",'"+key+"').map(item=>",'Пагинация '+key)

    # Insert footer after each analytics table; key it to section to avoid
    # mixing pages when switching between customer views and access roles.
    def inject_footer(text, unique_heading, jsx):
        pos=text.find(unique_heading)
        if pos<0 or text.find(unique_heading,pos+1)>=0:
            raise ValueError('Неоднозначный раздел аналитики: '+unique_heading)
        end=text.find('</section>',pos)
        if end<0:
            raise ValueError('Не найден конец раздела: '+unique_heading)
        return text[:end]+jsx+text[end:]
    analytics=inject_footer(analytics,'<h2>Роли банковского приложения</h2>',"\n        {pager(bankRoles,'bankRoles')}\n      ")
    analytics=inject_footer(analytics,'<h2>Роли PostgreSQL</h2>',"\n        {pager(roles,'postgresRoles')}\n      ")
    analytics=inject_footer(analytics,"<h2>{view==='accounts'?'Счета клиентов'", "\n            {pager(view==='accounts'?analytics.customers:view==='loans'?analytics.loans:analytics.contacts,`views:${view}`)}\n          ")
    analytics=inject_footer(analytics,'<h2>Результаты по филиалам</h2>',"\n            {pager(analytics.branches,'branches')}\n          ")

    # Validate expected component usage before writing any files.
    if main.count('<BankPagination ')!=2 or analytics.count('pager(')!=4 or analytics.count('pageRows(')!=6:
        raise ValueError('Внутренняя проверка не пройдена; файлы не изменены.')
except (ValueError, IndexError) as err:
    sys.exit(f'Обновление не применено: {err}\nПожалуйста, пришли текущие src/main.jsx и src/BankAnalyticsPage.jsx.')

css_add='''
/* Unified pagination across all Northstar Bank table sections */
.bank-pagination{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px;padding:17px 22px}
.bank-pagination .table-footer-left,.bank-pagination .table-footer-navigation{display:flex;align-items:center;gap:12px;flex-wrap:wrap}
.bank-pagination .page-size-control,.bank-pagination .page-picker{display:inline-flex;align-items:center;gap:8px;white-space:nowrap}
.bank-pagination .page-size-control select,.bank-pagination .page-picker select{height:34px;min-width:68px;padding:0 26px 0 9px;border:1px solid #dfe7f2;border-radius:9px;background:#fff;color:#344361;font:inherit;cursor:pointer}
.bank-pagination .page-size-control select:focus-visible,.bank-pagination .page-picker select:focus-visible{outline:2px solid #80aaff;outline-offset:2px}
.bank-pagination button{width:30px;height:34px;display:grid;place-items:center}
.bank-pagination button:disabled{opacity:.4;cursor:not-allowed}
@media(max-width:760px){.bank-pagination{align-items:flex-start}.bank-pagination .table-footer-left,.bank-pagination .table-footer-navigation{gap:9px}}
'''
if '/* Unified pagination across all Northstar Bank table sections */' not in styles:
    styles+='\n'+css_add

# Keep all backups outside of Git; never read or alter .env, SQL, or API files.
backup=root.parent / f'{root.name}_before_all_pagination_{datetime.now():%Y%m%d_%H%M%S}'
backup.mkdir(parents=True,exist_ok=False)
for file in [main_file,analytics_file,style_file]:
    shutil.copy2(file,backup/file.name)
if component_file.exists():
    shutil.copy2(component_file,backup/component_file.name)
main_file.write_text(main,encoding='utf-8')
analytics_file.write_text(analytics,encoding='utf-8')
style_file.write_text(styles,encoding='utf-8')
shutil.copy2(Path(__file__).with_name('BankPagination.jsx'),component_file)
print('Готово! Пагинация добавлена во все реестры, кредитный скоринг и таблицы аналитики/ролей.')
print('Для каждого раздела: 25 записей по умолчанию, выбор 10/25/50/100, список страниц.')
print('Сортировка транзакций (новые сверху) сохранена.')
print('Резервная копия файлов:',backup)
print('Обнови страницу сайта; если Vite остановлен, запусти npm run dev.')
