Northstar Bank — единая пагинация для всех таблиц

Что изменится:
- Клиенты, счета, транзакции, переводы, кредиты, платежи по кредитам,
  филиалы, сотрудники, владельцы счетов и акционеры.
- Кредитный скоринг.
- Аналитика: клиенты и счета, кредиты, контакты, филиалы,
  роли приложения и роли PostgreSQL.
- По умолчанию 25 строк; можно выбрать 10, 25, 50 или 100.
- Выбор страницы через выпадающий список + кнопки вперед/назад.
- В таблице транзакций новые записи по-прежнему показываются первыми.
- Размер страницы запоминается отдельно для каждого раздела в рамках сессии сайта.

УСТАНОВКА (внутри текущей папки проекта, где package.json):

1) Скачай Northstar_Bank_All_Sections_Pagination_Update.zip в Downloads.
2) В VS Code открой Terminal. Проверь pwd и ls (должен быть package.json).
3) Выполни:
   unzip -o ~/Downloads/Northstar_Bank_All_Sections_Pagination_Update.zip -d .
   python3 apply_all_pagination.py
4) Обнови сайт Command + R. Если сайт остановлен: npm run dev

Скрипт создаёт резервные копии исходных main.jsx,
BankAnalyticsPage.jsx, style.css ВНЕ папки проекта.

НЕ ЗАТРАГИВАЕТ: .env, PostgreSQL, API, SQL, роли или денежные операции.

Если скрипт сообщил, что структура отличается, он НЕ изменит файлы;
пришли текущие src/main.jsx и src/BankAnalyticsPage.jsx для точечной адаптации.

GitHub (при желании):
 git add src/main.jsx src/BankAnalyticsPage.jsx src/style.css src/BankPagination.jsx
 git commit -m "Add pagination to all bank sections"
 git push
