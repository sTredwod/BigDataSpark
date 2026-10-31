"""BigDataSpark lab 2: PostgreSQL mock_data -> PostgreSQL star schema using Spark.

Run in the project's Spark container with the PostgreSQL JDBC driver:
  spark-submit --master local[2] --jars /opt/spark/work-dir/jobs/postgresql-42.7.14.jar \
    /opt/spark/work-dir/jobs/01_build_star.py

Re-running rebuilds ONLY the generated dim_* and fact_sales tables. The
public.mock_data source table is never modified.
"""

from pyspark.sql import SparkSession, functions as F
from pyspark.sql.types import DecimalType

JDBC_URL = "jdbc:postgresql://postgres:5432/bigdata"
USER = "student"
PASSWORD = "student123"
JDBC_OPTIONS = {
    "url": JDBC_URL,
    "user": USER,
    "password": PASSWORD,
    "driver": "org.postgresql.Driver",
}

DIM_TABLES = [
    "dim_customer",
    "dim_seller",
    "dim_product",
    "dim_store",
    "dim_supplier",
    "dim_date",
]


def key_of(*column_names):
    """Stable surrogate key derived from the explicit natural key fields."""
    return F.sha2(F.to_json(F.struct(*[F.col(name) for name in column_names])), 256)


def save(df, table):
    (df.write.format("jdbc")
     .options(**JDBC_OPTIONS)
     .option("dbtable", f"public.{table}")
     .mode("errorifexists")
     .save())
    print(f"CREATED {table}: {df.count()} rows", flush=True)


def main():
    spark = (SparkSession.builder
             .appName("BigDataSpark_01_build_star")
             .master("local[2]")
             .config("spark.sql.shuffle.partitions", "8")
             .getOrCreate())
    spark.sparkContext.setLogLevel("WARN")

    connection = None
    try:
        raw = (spark.read.format("jdbc")
               .options(**JDBC_OPTIONS)
               .option("dbtable", "public.mock_data")
               .option("fetchsize", "2000")
               .load())
        raw_count = raw.count()
        print(f"SOURCE mock_data: {raw_count} rows", flush=True)
        if raw_count != 10_000:
            raise ValueError(f"Expected 10000 source rows, got {raw_count}")

        # The CSV's id and sale_*_id repeat across files. row_id is unique.
        # Customer/seller emails identify individual records, whereas the raw
        # numeric IDs do not. Product grain: name + category + brand.
        base = (raw
                .withColumn("customer_id", key_of("customer_email"))
                .withColumn("seller_id", key_of("seller_email"))
                .withColumn("product_id", key_of("product_name", "product_category", "product_brand"))
                .withColumn("store_id", key_of("store_name"))
                .withColumn("supplier_id", key_of("supplier_name"))
                .withColumn("sold_on", F.to_date(F.col("sale_date"), "M/d/yyyy"))
                .withColumn("date_id", F.date_format("sold_on", "yyyyMMdd").cast("int")))

        if base.filter(F.col("sold_on").isNull()).limit(1).count():
            raise ValueError("One or more sale_date values could not be parsed")

        dim_customer = (base.select(
            "customer_id", "customer_email", "customer_first_name", "customer_last_name",
            F.col("customer_age").cast("int").alias("customer_age"),
            "customer_country", "customer_postal_code", "customer_pet_type",
            "customer_pet_name", "customer_pet_breed")
            .dropDuplicates(["customer_id"]))

        dim_seller = (base.select(
            "seller_id", "seller_email", "seller_first_name", "seller_last_name",
            "seller_country", "seller_postal_code")
            .dropDuplicates(["seller_id"]))

        dim_product = (base.select(
            "product_id", "product_name", "product_category", "product_brand")
            .dropDuplicates(["product_id"]))

        # Store / supplier names repeat while their reported geographic fields
        # change across rows. Keep the geography on each sale for accurate
        # geographical reporting, rather than choosing an arbitrary location.
        dim_store = (base.select("store_id", "store_name")
                     .dropDuplicates(["store_id"]))
        dim_supplier = (base.select("supplier_id", "supplier_name")
                        .dropDuplicates(["supplier_id"]))

        dim_date = (base.select("date_id", F.col("sold_on").alias("sale_date"))
                    .dropDuplicates(["date_id"])
                    .withColumn("year", F.year("sale_date"))
                    .withColumn("quarter", F.quarter("sale_date"))
                    .withColumn("month", F.month("sale_date"))
                    .withColumn("day", F.dayofmonth("sale_date")))

        fact_sales = base.select(
            F.col("row_id").cast("long").alias("sale_id"),
            F.col("id").cast("int").alias("original_file_id"),
            "customer_id", "seller_id", "product_id", "store_id", "supplier_id", "date_id",
            F.col("sale_quantity").cast("int").alias("quantity"),
            F.col("sale_total_price").cast(DecimalType(14, 2)).alias("sale_amount"),
            F.col("product_price").cast(DecimalType(14, 2)).alias("unit_price"),
            F.col("product_rating").cast(DecimalType(3, 1)).alias("product_rating"),
            F.col("product_reviews").cast("int").alias("product_reviews"),
            "store_city", "store_country", "supplier_country"
        )

        if fact_sales.filter(
            F.col("sale_id").isNull() | F.col("sale_amount").isNull() |
            F.col("quantity").isNull() | F.col("date_id").isNull()
        ).limit(1).count():
            raise ValueError("Required fact fields contain null after conversion")

        # Rebuild only the lab's generated tables. Never touch mock_data.
        properties = spark._jvm.java.util.Properties()
        properties.setProperty("user", USER)
        properties.setProperty("password", PASSWORD)
        connection = spark._jvm.org.postgresql.Driver().connect(JDBC_URL, properties)
        statement = connection.createStatement()
        try:
            statement.execute("DROP TABLE IF EXISTS public.fact_sales CASCADE")
            for table in DIM_TABLES:
                statement.execute(f"DROP TABLE IF EXISTS public.{table} CASCADE")
        finally:
            statement.close()

        for table, frame in [
            ("dim_customer", dim_customer),
            ("dim_seller", dim_seller),
            ("dim_product", dim_product),
            ("dim_store", dim_store),
            ("dim_supplier", dim_supplier),
            ("dim_date", dim_date),
            ("fact_sales", fact_sales),
        ]:
            save(frame, table)

        # Make the dimensions and facts a real relational star schema, with
        # primary keys and enforced relationships in PostgreSQL.
        statement = connection.createStatement()
        try:
            for table, key in [
                ("dim_customer", "customer_id"),
                ("dim_seller", "seller_id"),
                ("dim_product", "product_id"),
                ("dim_store", "store_id"),
                ("dim_supplier", "supplier_id"),
                ("dim_date", "date_id"),
                ("fact_sales", "sale_id"),
            ]:
                statement.execute(f"ALTER TABLE public.{table} ADD PRIMARY KEY ({key})")

            for dim, key in [
                ("customer", "customer_id"),
                ("seller", "seller_id"),
                ("product", "product_id"),
                ("store", "store_id"),
                ("supplier", "supplier_id"),
                ("date", "date_id"),
            ]:
                statement.execute(
                    f"ALTER TABLE public.fact_sales ADD CONSTRAINT fk_fact_{dim} "
                    f"FOREIGN KEY ({key}) REFERENCES public.dim_{dim} ({key})"
                )
        finally:
            statement.close()

        print("SUCCESS: PostgreSQL star schema created with primary/foreign keys.", flush=True)
    finally:
        if connection is not None:
            connection.close()
        spark.stop()


if __name__ == "__main__":
    main()
