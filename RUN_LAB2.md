# BigDataSpark — лабораторная работа №2

## Состав проекта

- `исходные данные/` — 10 CSV-файлов, суммарно 10 000 строк.
- `docker-compose.yml` — PostgreSQL 16, Apache Spark 3.5.5, ClickHouse 25.3.
- `load_mock_data.ps1` — загрузка CSV в PostgreSQL (`public.mock_data`).
- `jobs/postgresql-42.7.14.jar` — JDBC-драйвер PostgreSQL (необходимо скачать).
- `jobs/01_build_star.py` — Spark ETL: исходные строки → модель звезды в PostgreSQL.
- `jobs/02_build_clickhouse.py` — Spark ETL: модель звезды → 6 отчётов в ClickHouse.
- `jobs/check_reports.sql` — примеры аналитических запросов и проверка витрин.

## Запуск в Windows PowerShell (из корня проекта)

### 1. Запуск сервисов

```powershell
docker compose up -d
docker compose ps
```

Убедитесь, что `postgres`, `spark` и `clickhouse` запущены; `postgres` — `healthy`.

### 2. Подготовка PostgreSQL

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\load_mock_data.ps1
```

В `mock_data` должно быть 10 000 строк. *Этот скрипт очищает и заново наполняет только `mock_data`.*

### 3. JDBC-драйвер для Spark

```powershell
Invoke-WebRequest -Uri "https://jdbc.postgresql.org/download/postgresql-42.7.14.jar" -OutFile ".\jobs\postgresql-42.7.14.jar"
```

### 4. Построение модели звезды в PostgreSQL

```powershell
docker compose exec -T spark /opt/spark/bin/spark-submit --master "local[2]" --driver-memory 2g --jars /opt/spark/work-dir/jobs/postgresql-42.7.14.jar /opt/spark/work-dir/jobs/01_build_star.py
```

Ожидается сообщение `SUCCESS: PostgreSQL star schema created with primary/foreign keys.`

### 5. Формирование шести отчётов в ClickHouse

```powershell
docker compose exec -T spark /opt/spark/bin/spark-submit --master "local[2]" --driver-memory 2g --jars /opt/spark/work-dir/jobs/postgresql-42.7.14.jar /opt/spark/work-dir/jobs/02_build_clickhouse.py
```

Ожидается `SUCCESS: six ClickHouse reports created; each covers all 10000 sales.`

### 6. Проверка отчётов

```powershell
Get-Content -Raw -Encoding UTF8 .\jobs\check_reports.sql | docker compose exec -T clickhouse clickhouse-client --user student --password student123 --database bigdata --multiquery
```

В БД `bigdata` должны присутствовать **ровно 6 отчётных таблиц**:

1. `report_product_sales` — товары, рейтинги, отзывы, продажи и выручка по категориям.
2. `report_customer_sales` — клиенты, страны, средний чек и топ по покупкам.
3. `report_time_sales` — продажи, выручка и средний чек по месяцам.
4. `report_store_sales` — магазины, города, страны, выручка и средний чек.
5. `report_supplier_sales` — поставщики, страны, выручка и средняя цена.
6. `report_product_quality` — качество товаров, рейтинги, отзывы и корреляция с продажами.

В последней секции `VALIDATION` для **каждого** отчёта сумма `sales` должна быть **10 000**.

## Особенности исходных данных

- Исходные `id` и `sale_*_id` не являются глобальными ключами: они повторяются между файлами. Скрипт загрузки добавляет уникальный `row_id`.
- Некоторые синтетические названия магазинов/поставщиков имеют разные местоположения в разных продажах. Витрины сохраняют географию на уровне записи о продаже; запросы к топу магазинов/поставщиков группируют строки обратно по сущности.
- `product_reviews` может отличаться у строк одного и того же товара: используется максимум как значение количества отзывов; суммирование создало бы двойной счёт.
- В исходных CSV все продажи относятся к **2021 году**. Можно сравнивать месяцы, но нельзя рассчитывать полноценный рост год-к-году на данных этого набора.
- Факты и измерения построены в Spark. Для передачи готовых агрегатов в ClickHouse используется HTTP API ClickHouse (из стандартной библиотеки Python); дополнительный ClickHouse JDBC-драйвер не нужен.
- Повторный запуск `01_build_star.py` пересоздаёт только измерения и факты. Повторный запуск `02_build_clickhouse.py` очищает и заново заполняет только шесть отчётов. Исходные CSV не изменяются.
- Тестовые учётные данные БД предназначены только для локальной лабораторной среды.

## Остановка без удаления данных

```powershell
docker compose down
```

**Не используйте `docker compose down -v`**, если необходимо сохранить PostgreSQL и ClickHouse.
