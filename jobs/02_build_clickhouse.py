"""Lab 2, stage 2: Spark reads PostgreSQL star schema and builds 6 ClickHouse marts.

Uses the existing PostgreSQL JDBC driver and ClickHouse's built-in HTTP API.
No ClickHouse JDBC driver or third-party Python package is required.

Run in the project's Spark container:
  /opt/spark/bin/spark-submit --master 'local[2]' --driver-memory 2g \
    --jars /opt/spark/work-dir/jobs/postgresql-42.7.14.jar \
    /opt/spark/work-dir/jobs/02_build_clickhouse.py

Rerunning replaces ONLY the six report_* tables in the ClickHouse bigdata
schema. PostgreSQL source, dimensions and fact_sales are never modified.
"""

import base64
import math
import os
import urllib.error
import urllib.request

from pyspark.sql import SparkSession, functions as F

PG_URL = os.getenv("PG_URL", "jdbc:postgresql://postgres:5432/bigdata")
PG_USER = os.getenv("PG_USER", "student")
PG_PASSWORD = os.getenv("PG_PASSWORD", "student123")
CH_URL = os.getenv("CH_URL", "http://clickhouse:8123/")
CH_USER = os.getenv("CH_USER", "student")
CH_PASSWORD = os.getenv("CH_PASSWORD", "student123")

PG_OPTIONS = {
    "url": PG_URL,
    "user": PG_USER,
    "password": PG_PASSWORD,
    "driver": "org.postgresql.Driver",
}


# Exactly six materialized report tables. Each table contains enough metrics
# and dimensions for the top-N, geographical, temporal and quality queries
# specified in the assignment (see check_reports.sql).
REPORT_DDL = {
    "report_product_sales": """
        product_id String,
        product_name String,
        product_category String,
        product_brand String,
        sales_count UInt64,
        units_sold UInt64,
        total_revenue Float64,
        avg_rating Float64,
        reviews_count UInt64
    """,
    "report_customer_sales": """
        customer_id String,
        customer_email String,
        customer_name String,
        customer_country String,
        sales_count UInt64,
        units_sold UInt64,
        total_revenue Float64,
        avg_order_value Float64
    """,
    "report_time_sales": """
        sale_year Int32,
        sale_month Int32,
        sales_count UInt64,
        units_sold UInt64,
        total_revenue Float64,
        avg_order_value Float64
    """,
    "report_store_sales": """
        store_id String,
        store_name String,
        store_city String,
        store_country String,
        sales_count UInt64,
        units_sold UInt64,
        total_revenue Float64,
        avg_order_value Float64
    """,
    "report_supplier_sales": """
        supplier_id String,
        supplier_name String,
        supplier_country String,
        sales_count UInt64,
        units_sold UInt64,
        total_revenue Float64,
        price_sum Float64,
        price_count UInt64,
        avg_product_price Float64
    """,
    "report_product_quality": """
        product_id String,
        product_name String,
        product_category String,
        product_brand String,
        sales_count UInt64,
        units_sold UInt64,
        total_revenue Float64,
        avg_rating Float64,
        reviews_count UInt64,
        rating_sales_correlation Nullable(Float64)
    """,
}

REPORT_ORDER = {
    "report_product_sales": "product_id",
    "report_customer_sales": "customer_id",
    "report_time_sales": "(sale_year, sale_month)",
    "report_store_sales": "(store_id, store_country, store_city)",
    "report_supplier_sales": "(supplier_id, supplier_country)",
    "report_product_quality": "product_id",
}


def ch_query(query):
    """Execute a single SQL statement via the ClickHouse HTTP endpoint."""
    basic = base64.b64encode(f"{CH_USER}:{CH_PASSWORD}".encode("utf-8")).decode("ascii")
    request = urllib.request.Request(
        CH_URL,
        data=query.encode("utf-8"),
        method="POST",
        headers={
            "Authorization": "Basic " + basic,
            "Content-Type": "text/plain; charset=utf-8",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        details = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"ClickHouse HTTP {exc.code}: {details[:3000]}") from exc


def read_pg(spark, table):
    return (spark.read.format("jdbc")
            .options(**PG_OPTIONS)
            .option("dbtable", "public." + table)
            .option("fetchsize", "2000")
            .load())


def measures():
    """Per-sale metrics (one fact row represents one transaction line)."""
    return [
        F.count("*").cast("long").alias("sales_count"),
        F.sum(F.col("quantity").cast("long")).cast("long").alias("units_sold"),
        F.round(F.sum(F.col("sale_amount").cast("double")), 2).alias("total_revenue"),
    ]


def average_order():
    return F.round(F.avg(F.col("sale_amount").cast("double")), 2).alias("avg_order_value")


def save_report(df, table):
    """Stream Spark JSON rows to ClickHouse in batches, without extra packages."""
    schema = REPORT_DDL[table]
    ch_query(f"CREATE TABLE IF NOT EXISTS bigdata.{table} ({schema}) "
             f"ENGINE = MergeTree ORDER BY {REPORT_ORDER[table]}")
    # Reruns must be idempotent: do not duplicate report rows.
    ch_query(f"TRUNCATE TABLE bigdata.{table}")

    batch = []
    inserted = 0
    for json_row in df.toJSON().toLocalIterator():
        batch.append(json_row)
        if len(batch) >= 500:
            ch_query(f"INSERT INTO bigdata.{table} FORMAT JSONEachRow\n" + "\n".join(batch) + "\n")
            inserted += len(batch)
            batch.clear()
    if batch:
        ch_query(f"INSERT INTO bigdata.{table} FORMAT JSONEachRow\n" + "\n".join(batch) + "\n")
        inserted += len(batch)

    checked = int(ch_query(f"SELECT count() FROM bigdata.{table}").strip())
    if checked != inserted or not checked:
        raise RuntimeError(f"{table}: uploaded {inserted}, ClickHouse contains {checked}")
    print(f"CREATED {table}: {checked} rows", flush=True)


def main():
    spark = (SparkSession.builder
             .appName("BigDataSpark_02_build_clickhouse")
             .master("local[2]")
             .config("spark.sql.shuffle.partitions", "8")
             .getOrCreate())
    spark.sparkContext.setLogLevel("WARN")
    try:
        f = read_pg(spark, "fact_sales")
        p = read_pg(spark, "dim_product")
        c = read_pg(spark, "dim_customer")
        d = read_pg(spark, "dim_date")
        s = read_pg(spark, "dim_store")
        sp = read_pg(spark, "dim_supplier")

        fact_count = f.count()
        print(f"SOURCE fact_sales: {fact_count} rows", flush=True)
        if fact_count != 10_000:
            raise ValueError(f"Expected 10000 rows in PostgreSQL fact_sales, got {fact_count}")
        ch_query("CREATE DATABASE IF NOT EXISTS bigdata")

        # 1. Products: one row per distinct product (name + category + brand).
        products = (f.join(p, "product_id")
                    .groupBy("product_id", "product_name", "product_category", "product_brand")
                    .agg(*measures(),
                         F.round(F.avg(F.col("product_rating").cast("double")), 2).alias("avg_rating"),
                         # Synthetic data can repeat a product with different review snapshots.
                         # MAX is a defensible snapshot metric; SUM would double-count reviews.
                         F.max("product_reviews").cast("long").alias("reviews_count")))
        save_report(products, "report_product_sales")

        # 2. Customers: one row per email; group table in CH for country distribution.
        customers = (f.join(c, "customer_id")
                     .withColumn("customer_name", F.concat_ws(" ", "customer_first_name", "customer_last_name"))
                     .groupBy("customer_id", "customer_email", "customer_name", "customer_country")
                     .agg(*measures(), average_order()))
        save_report(customers, "report_customer_sales")

        # 3. Time: one row for each year/month combination.
        temporal = (f.join(d, "date_id")
                    .groupBy(F.col("year").alias("sale_year"),
                             F.col("month").alias("sale_month"))
                    .agg(*measures(), average_order()))
        save_report(temporal, "report_time_sales")

        # 4. Stores: geography is stored on the sale, not in dim_store,
        # because the generated source inconsistently assigns locations to names.
        stores = (f.join(s, "store_id")
                  .groupBy("store_id", "store_name", "store_city", "store_country")
                  .agg(*measures(), average_order()))
        save_report(stores, "report_store_sales")

        # 5. Suppliers: aggregate by supplier and geography, with price_sum
        # and price_count so global weighted mean can be computed correctly.
        suppliers = (f.join(sp, "supplier_id")
                     .groupBy("supplier_id", "supplier_name", "supplier_country")
                     .agg(*measures(),
                          F.round(F.sum(F.col("unit_price").cast("double")), 2).alias("price_sum"),
                          F.count("unit_price").cast("long").alias("price_count"),
                          F.round(F.avg(F.col("unit_price").cast("double")), 2).alias("avg_product_price")))
        save_report(suppliers, "report_supplier_sales")

        # 6. Product quality: one row per product, with global Pearson
        # correlation between its average rating and units sold.
        quality = (f.join(p, "product_id")
                   .groupBy("product_id", "product_name", "product_category", "product_brand")
                   .agg(*measures(),
                        F.round(F.avg(F.col("product_rating").cast("double")), 2).alias("avg_rating"),
                        F.max("product_reviews").cast("long").alias("reviews_count")))
        correlation = quality.select(F.corr("avg_rating", "units_sold")).first()[0]
        if correlation is not None and not math.isfinite(correlation):
            correlation = None
        quality = quality.withColumn("rating_sales_correlation", F.lit(correlation).cast("double"))
        save_report(quality, "report_product_quality")

        # Every grouped report must cover all original transactions exactly once.
        for table in REPORT_DDL:
            count = int(ch_query(f"SELECT sum(sales_count) FROM bigdata.{table}").strip())
            if count != fact_count:
                raise RuntimeError(f"{table}: sales_count sums to {count}, expected {fact_count}")
        print("SUCCESS: six ClickHouse reports created; each covers all 10000 sales.", flush=True)
        print(f"Product rating / units sold Pearson correlation: {correlation}", flush=True)
    finally:
        spark.stop()


if __name__ == "__main__":
    main()
