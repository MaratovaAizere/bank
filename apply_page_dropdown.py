#!/usr/bin/env python3
"""Replace the numeric page-jump form with a dropdown in Northstar Bank."""
from pathlib import Path
import shutil
import sys

project = Path.cwd()
main = project / 'src' / 'main.jsx'
css_file = project / 'src' / 'style.css'
if not (project / 'package.json').is_file() or not main.is_file() or not css_file.is_file():
    sys.exit('Ошибка: запусти команду из папки проекта (где package.json и src/main.jsx).')

source = main.read_text(encoding='utf-8')
styles = css_file.read_text(encoding='utf-8')
if 'aria-label="Выбрать страницу"' in source:
    print('Выпадающий список страниц уже установлен. Повторять не нужно.')
    sys.exit(0)

old = '''    <span>{current} / {totalPages}</span>
    {entity==='transactions'&&<form className="page-jump" key={`${entity}-${current}`} onSubmit={e=>{
      e.preventDefault();
      const target=Number(e.currentTarget.elements.namedItem('targetPage')?.value);
      if(Number.isFinite(target))setPageNum(Math.max(1,Math.min(totalPages,Math.trunc(target))));
    }}>
      <label>Страница <input type="number" name="targetPage" aria-label="Перейти на страницу" min="1" max={totalPages} defaultValue={current}/></label>
      <button type="submit">Перейти</button>
    </form>}'''

new = '''    {entity==='transactions'?<>
      <label className="page-jump page-picker">Страница
        <select aria-label="Выбрать страницу" value={current} onChange={e=>setPageNum(Number(e.target.value))}>
          {Array.from({length:totalPages},(_,i)=><option key={i+1} value={i+1}>{i+1}</option>)}
        </select>
      </label>
      <span>из {totalPages}</span>
    </>:<span>{current} / {totalPages}</span>}'''

if source.count(old) != 1:
    sys.exit('Не нашла ожидаемую разметку. Файлы не изменены. Убедись, что предыдущее обновление пагинации установлено; иначе пришли src/main.jsx.')
new_source = source.replace(old, new, 1)

# Styling for a native accessible dropdown; keep the previous paginator rules otherwise.
css_add = '''
/* Page number dropdown (Northstar Bank transactions) */
.page-jump.page-picker{display:inline-flex;align-items:center;gap:8px;white-space:nowrap}
.page-jump.page-picker select{height:34px;min-width:68px;padding:0 28px 0 10px;border:1px solid #dfe7f2;border-radius:9px;background:#fff;color:#344361;font:inherit;cursor:pointer}
.page-jump.page-picker select:focus-visible{outline:2px solid #80aaff;outline-offset:2px}
'''
if '/* Page number dropdown (Northstar Bank transactions) */' not in styles:
    styles += css_add

backup = project.parent / (project.name + '_page_dropdown_backup')
backup.mkdir(parents=True, exist_ok=True)
shutil.copy2(main, backup / 'main.jsx')
shutil.copy2(css_file, backup / 'style.css')
main.write_text(new_source, encoding='utf-8')
css_file.write_text(styles, encoding='utf-8')
print('Готово: у транзакций вместо ввода номера и кнопки «Перейти» появился выпадающий список страниц.')
print('Изменены src/main.jsx и src/style.css. Резервная копия:', backup)
print('В браузере обнови страницу; если нужно, перезапусти npm run dev.')
