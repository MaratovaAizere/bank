# Northstar Bank — Views, Scoring, Transactions

## Что изменено

- `server/scoring.js`: API читает `public.v_credit_scoring_normalized` вместо длинного SQL внутри JavaScript. Рейтинг 0–1, один знак после запятой, уровни риска и объяснения сохранены.
- `server/index.js`: общий отчёт читает `public.v_bank_summary`; список транзакций — `public.v_transaction_balances`. Операции с транзакциями выполняются внутри `BEGIN/COMMIT` с `ROLLBACK` при ошибке.
- `database/upgrade_scoring_transactions.sql`: создаёт Views и триггер, который атомарно меняет баланс при переводе, пополнении и снятии, возвращает остатки до/после и компенсирует проведённую операцию при отклонении/отмене.
- `src/main.jsx`, `src/data.js`: баланс счёта нельзя менять вручную через форму; транзакции показывают остатки и могут быть отменены через меню действий.
- `database/test_scoring_transactions.sql`: проверяет операции внутри транзакции, которая целиком откатывается.

## Установка на Mac (в существующий проект!)

1. Остановите API и Vite (`Control+C` в соответствующих терминалах).
2. Сохраните резервную копию файлов и базы:

```bash
cd ~/Downloads/"bank-frontend 4"
cp -R . ~/Downloads/bank-frontend-before-upgrade
pg_dump -U postgres -h localhost -p 5432 -d bank_database -Fc -f ~/Downloads/bank_database_before_upgrade.dump
```

Если папка `~/Downloads/bank-frontend-before-upgrade` уже существует, используйте другое имя. Если `pg_dump` недоступен в PATH, используйте `/Library/PostgreSQL/18/bin/pg_dump`.

3. Распакуйте этот ZIP в открытую папку проекта:

```bash
unzip -o ~/Downloads/Northstar_Bank_Scoring_Transactions_Update.zip -d .
```

4. Выполните миграцию **только один раз на нужной базе**, повторный запуск миграции безопасен:

```bash
psql -U postgres -h localhost -p 5432 -d bank_database -v ON_ERROR_STOP=1 -f database/upgrade_scoring_transactions.sql
```

5. Проверьте обновление (тестовые операции не сохраняются):

```bash
psql -U postgres -h localhost -p 5432 -d bank_database -v ON_ERROR_STOP=1 -f database/test_scoring_transactions.sql
```

Ожидается сообщение `NOTICE: PASS: deposit ...` и `ROLLBACK`. Если тест не прошёл, пришлите полный текст ошибки без паролей.

6. Запустите API и сайт в двух терминалах:

```bash
npm run server
```

```bash
npm run dev
```

Откройте http://localhost:5173/ и войдите со своим существующим токеном.

## Проверка Views

```sql
SELECT * FROM public.v_credit_scoring_normalized LIMIT 5;
SELECT * FROM public.v_bank_summary;
SELECT * FROM public.v_transaction_balances ORDER BY transaction_id DESC LIMIT 5;
```

## Как работает проводка

- `pending`: не меняет баланс;
- `completed`: списание/пополнение/перевод меняет баланс и возвращает `from_balance_before`, `from_balance_after`, `to_balance_before`, `to_balance_after`;
- `completed → failed/cancelled`: компенсирующая запись возвращает денежный эффект и показывает баланс после возврата;
- `pending → failed/cancelled`: денег не перемещает;
- если на счёте недостаточно средств для перевода/отмены, ошибка откатывает всё целиком, статус и балансы не меняются;
- повторный `completed → completed` не списывает деньги ещё раз;
- уже отменённую/отклонённую операцию нельзя провести повторно: создайте новую.

**Важные ограничения:** ранее импортированные транзакции считаются историческими (существующие балансы уже включают их результаты). Миграция **не пересчитывает** их повторно; отменить старую проведённую запись с неизвестным исходным денежным эффектом нельзя. Раздел `transfers` в проекте — отдельный реестр, и этот балансный механизм относится только к разделу `transactions` (включая тип «Перевод»).

Реальные банковские системы требуют отдельного неизменяемого журнала бухгалтерских проводок, двойной записи, контроля разрешений по операциям, аудита и защиты от повторной отправки запроса. Это улучшение учебного проекта, не готовая промышленная платёжная система.

**Секреты:** ZIP не содержит `.env`, пароль БД, токены, `node_modules` или дамп пользовательских данных.
