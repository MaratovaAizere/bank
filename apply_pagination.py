#!/usr/bin/env python3
"""Safely update only the transactions table pagination in a Northstar Bank React project."""
from pathlib import Path
import shutil
import sys

project = Path.cwd()
main = project / "src" / "main.jsx"
style = project / "src" / "style.css"

if not main.is_file() or not style.is_file() or not (project / "package.json").is_file():
    sys.exit('Ошибка: открой терминал в корне bank-frontend (где package.json и папка src).')

s = main.read_text(encoding='utf-8')
css = style.read_text(encoding='utf-8')
if 'page-size-control' in s or 'transactionPageSize' in s:
    sys.exit('Изменения уже установлены. Повторно применять не нужно.')

state_anchor = '[pageNum,setPageNum]=useState(1),'
calc_anchor = 'const totalPages=Math.max(1,Math.ceil(filtered.length/8)),current=Math.min(pageNum,totalPages),rows=filtered.slice((current-1)*8,current*8);'
footer_begin = '<div className="table-footer">'
footer_end = '</section>'
if s.count(state_anchor) != 1 or s.count(calc_anchor) != 1 or s.count(footer_begin) != 1:
    sys.exit('Структура src/main.jsx отличается от ожидаемой. Файлы НЕ изменены. Пришли мне свой src/main.jsx.')

s = s.replace(state_anchor, state_anchor + '[transactionPageSize,setTransactionPageSize]=useState(25),', 1)

# Transactions only: newest ID first unless the user has chosen a column sort.
calculation = '''if(entity==='transactions'&&!sort){filtered=[...filtered].sort((a,b)=>{
 const aId=Number(a.transaction_id),bId=Number(b.transaction_id);
 if(Number.isFinite(aId)&&Number.isFinite(bId))return bId-aId;
 return String(b.transaction_date??'').localeCompare(String(a.transaction_date??''),'ru',{numeric:true});
})}
const pageSize=entity==='transactions'?transactionPageSize:8;
const totalPages=Math.max(1,Math.ceil(filtered.length/pageSize)),current=Math.max(1,Math.min(pageNum,totalPages)),rows=filtered.slice((current-1)*pageSize,current*pageSize);'''
s = s.replace(calc_anchor, calculation, 1)

start = s.index(footer_begin)
end = s.index(footer_end, start)
old_footer = s[start:end]
if 'Показано' not in old_footer or 'current-1)*8' not in old_footer:
    sys.exit('Неизвестная разметка таблицы. Файлы НЕ изменены.')

new_footer = '''<div className="table-footer">
  <div className="table-footer-left">
    <span>Показано {filtered.length?((current-1)*pageSize+1):0}–{Math.min(current*pageSize,filtered.length)} из {filtered.length}</span>
    {entity==='transactions'&&<label className="page-size-control">На странице:
      <select aria-label="Количество транзакций на странице" value={transactionPageSize} onChange={e=>{setTransactionPageSize(Number(e.target.value));setPageNum(1)}}>
        {[10,25,50,100].map(size=><option key={size} value={size}>{size}</option>)}
      </select>
    </label>}
  </div>
  <div className="table-footer-navigation">
    <button disabled={current===1} onClick={()=>setPageNum(current-1)} aria-label="Назад"><ChevronLeft size={18}/></button>
    <span>{current} / {totalPages}</span>
    {entity==='transactions'&&<form className="page-jump" key={`${entity}-${current}`} onSubmit={e=>{
      e.preventDefault();
      const target=Number(e.currentTarget.elements.namedItem('targetPage')?.value);
      if(Number.isFinite(target))setPageNum(Math.max(1,Math.min(totalPages,Math.trunc(target))));
    }}>
      <label>Страница <input type="number" name="targetPage" aria-label="Перейти на страницу" min="1" max={totalPages} defaultValue={current}/></label>
      <button type="submit">Перейти</button>
    </form>}
    <button disabled={current===totalPages} onClick={()=>setPageNum(current+1)} aria-label="Вперёд"><ChevronRight size={18}/></button>
  </div>
</div>'''
s = s[:start] + new_footer + s[end:]

# Show a descending arrow on the default transaction ID column, and reset pagination on manual sorting.
sort_anchor = "onClick={()=>{setSort(sort?.key===f[0]?{key:f[0],dir:sort.dir==='asc'?'desc':'asc'}:{key:f[0],dir:'asc'})}}"
if sort_anchor in s:
    s = s.replace(sort_anchor, "onClick={()=>{setSort(sort?.key===f[0]?{key:f[0],dir:sort.dir==='asc'?'desc':'asc'}:{key:f[0],dir:'asc'});setPageNum(1)}}", 1)
arrow_anchor = "sort?.key===f[0]?(sort.dir==='asc'?'↑':'↓'):''"
if arrow_anchor in s:
    s = s.replace(arrow_anchor, "sort?.key===f[0]?(sort.dir==='asc'?'↑':'↓'):(entity==='transactions'&&f[0]==='transaction_id'?'↓':'')", 1)

# Once a transaction is saved, bring the user back to the top of the latest-first list.
save_anchor = 'setModal(null);try{await refresh();notify('
if save_anchor in s:
    s = s.replace(save_anchor,"setModal(null);try{await refresh();if(entity==='transactions'){setSort(null);setPageNum(1)}notify(",1)

if 'page-size-control' not in s or 'page-jump' not in s or 'transactionPageSize' not in s:
    sys.exit('Ошибка внутренней проверки. Изменения НЕ сохранены.')

css_append = '''
/* Compact pagination controls in the transactions register */
.table-footer{flex-wrap:wrap;gap:12px}
.table-footer-left,.table-footer-navigation{display:flex;align-items:center;gap:12px;flex-wrap:wrap}
.page-size-control,.page-jump,.page-jump label{display:flex;align-items:center;gap:7px;white-space:nowrap}
.page-size-control select,.page-jump input{height:30px;border:1px solid #dfe7f2;background:#fff;border-radius:7px;color:#344361;font:inherit;padding:0 7px}
.page-size-control select{min-width:58px}
.page-jump input{width:55px;min-width:0}
.table-footer .page-jump button{width:auto;height:30px;padding:0 9px;display:inline-flex;font-weight:600;white-space:nowrap}
.table-footer button:disabled{opacity:.45;cursor:not-allowed}
@media(max-width:760px){.table-footer{align-items:flex-start}.table-footer-left,.table-footer-navigation{gap:9px}}
'''

# Backups outside Git/project, including a unique numeric suffix if necessary.
backup_dir = project.parent / (project.name + '_pagination_backup')
backup_dir.mkdir(parents=True, exist_ok=True)
shutil.copy2(main, backup_dir / 'main.jsx')
shutil.copy2(style, backup_dir / 'style.css')
main.write_text(s, encoding='utf-8')
style.write_text(css + css_append, encoding='utf-8')
print('Готово: новые транзакции сверху; 25 строк по умолчанию; 10/25/50/100; переход к странице.')
print('Обновлены: src/main.jsx и src/style.css')
print('Резервная копия:', backup_dir)
print('Теперь выполни: npm run dev')
