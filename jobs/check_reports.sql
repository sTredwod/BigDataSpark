-- BigDataSpark lab 2: six ClickHouse reports with examples for every requirement.
-- Run with: Get-Content -Raw .\jobs\check_reports.sql | docker compose exec -T clickhouse clickhouse-client --user student --password student123 --database bigdata --multiquery

-- 1. Product sales: top 10 by units, category revenue, ratings and reviews.
SELECT 'PRODUCT TOP 10' AS section;
SELECT product_name, product_category, units_sold, total_revenue
FROM report_product_sales ORDER BY units_sold DESC LIMIT 10;
SELECT product_category, round(sum(total_revenue), 2) AS category_revenue
FROM report_product_sales GROUP BY product_category ORDER BY category_revenue DESC;
SELECT product_name, product_category, avg_rating, reviews_count
FROM report_product_sales ORDER BY reviews_count DESC LIMIT 10;

-- 2. Customer sales: top 10, country counts and customer order averages.
SELECT 'CUSTOMERS' AS section;
SELECT customer_email, total_revenue, sales_count, avg_order_value
FROM report_customer_sales ORDER BY total_revenue DESC LIMIT 10;
SELECT customer_country, count() AS customers, round(sum(total_revenue), 2) AS revenue
FROM report_customer_sales GROUP BY customer_country ORDER BY customers DESC LIMIT 10;

-- 3. Time: monthly / annual trends and month-over-month revenue change.
-- Source CSV contains only 2021, so year-over-year cannot be calculated.
SELECT 'TIME' AS section;
SELECT sale_year, sale_month, sales_count, total_revenue, avg_order_value
FROM report_time_sales ORDER BY sale_year, sale_month;
SELECT sale_year, sum(sales_count) AS sales, round(sum(total_revenue), 2) AS revenue
FROM report_time_sales GROUP BY sale_year ORDER BY sale_year;
SELECT sale_year, sale_month, total_revenue,
       round(total_revenue - lagInFrame(total_revenue, 1, total_revenue)
           OVER (ORDER BY sale_year, sale_month), 2) AS change_from_previous_month
FROM report_time_sales ORDER BY sale_year, sale_month;

-- 4. Stores: top 5, geography and average receipt per store.
SELECT 'STORES' AS section;
SELECT store_name, sum(sales_count) AS sales, round(sum(total_revenue), 2) AS revenue,
       round(sum(total_revenue)/sum(sales_count), 2) AS avg_order_value
FROM report_store_sales GROUP BY store_id, store_name ORDER BY revenue DESC LIMIT 5;
SELECT store_country, store_city, sum(sales_count) AS sales,
       round(sum(total_revenue), 2) AS revenue
FROM report_store_sales GROUP BY store_country, store_city ORDER BY revenue DESC LIMIT 10;

-- 5. Suppliers: top 5, average item price and country distribution.
SELECT 'SUPPLIERS' AS section;
SELECT supplier_name, round(sum(total_revenue), 2) AS revenue,
       round(sum(price_sum)/nullIf(sum(price_count), 0), 2) AS avg_product_price
FROM report_supplier_sales GROUP BY supplier_id, supplier_name ORDER BY revenue DESC LIMIT 5;
SELECT supplier_country, sum(sales_count) AS sales, round(sum(total_revenue), 2) AS revenue
FROM report_supplier_sales GROUP BY supplier_country ORDER BY revenue DESC LIMIT 10;

-- 6. Quality: highest and lowest ratings, global correlation, most reviewed.
SELECT 'PRODUCT QUALITY' AS section;
SELECT product_name, product_category, avg_rating, units_sold
FROM report_product_quality ORDER BY avg_rating DESC LIMIT 10;
SELECT product_name, product_category, avg_rating, units_sold
FROM report_product_quality ORDER BY avg_rating ASC LIMIT 10;
SELECT any(rating_sales_correlation) AS pearson_rating_vs_units_sold
FROM report_product_quality;
SELECT product_name, product_category, reviews_count
FROM report_product_quality ORDER BY reviews_count DESC LIMIT 10;

-- Sanity check: each report counts exactly 10000 sales (source fact rows).
SELECT 'VALIDATION' AS section;
SELECT 'products' AS report, count() AS rows, sum(sales_count) AS sales FROM report_product_sales
UNION ALL SELECT 'customers', count(), sum(sales_count) FROM report_customer_sales
UNION ALL SELECT 'time', count(), sum(sales_count) FROM report_time_sales
UNION ALL SELECT 'stores', count(), sum(sales_count) FROM report_store_sales
UNION ALL SELECT 'suppliers', count(), sum(sales_count) FROM report_supplier_sales
UNION ALL SELECT 'quality', count(), sum(sales_count) FROM report_product_quality;
