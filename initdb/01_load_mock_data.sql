-- PostgreSQL initialization: runs automatically only for a NEW database volume.
-- The original CSV data stays unchanged.
CREATE TABLE public.mock_data (
    row_id BIGSERIAL PRIMARY KEY,
    "id" TEXT,
    "customer_first_name" TEXT,
    "customer_last_name" TEXT,
    "customer_age" TEXT,
    "customer_email" TEXT,
    "customer_country" TEXT,
    "customer_postal_code" TEXT,
    "customer_pet_type" TEXT,
    "customer_pet_name" TEXT,
    "customer_pet_breed" TEXT,
    "seller_first_name" TEXT,
    "seller_last_name" TEXT,
    "seller_email" TEXT,
    "seller_country" TEXT,
    "seller_postal_code" TEXT,
    "product_name" TEXT,
    "product_category" TEXT,
    "product_price" TEXT,
    "product_quantity" TEXT,
    "sale_date" TEXT,
    "sale_customer_id" TEXT,
    "sale_seller_id" TEXT,
    "sale_product_id" TEXT,
    "sale_quantity" TEXT,
    "sale_total_price" TEXT,
    "store_name" TEXT,
    "store_location" TEXT,
    "store_city" TEXT,
    "store_state" TEXT,
    "store_country" TEXT,
    "store_phone" TEXT,
    "store_email" TEXT,
    "pet_category" TEXT,
    "product_weight" TEXT,
    "product_color" TEXT,
    "product_size" TEXT,
    "product_brand" TEXT,
    "product_material" TEXT,
    "product_description" TEXT,
    "product_rating" TEXT,
    "product_reviews" TEXT,
    "product_release_date" TEXT,
    "product_expiry_date" TEXT,
    "supplier_name" TEXT,
    "supplier_contact" TEXT,
    "supplier_email" TEXT,
    "supplier_phone" TEXT,
    "supplier_address" TEXT,
    "supplier_city" TEXT,
    "supplier_country" TEXT
);

COPY public.mock_data ("id", "customer_first_name", "customer_last_name", "customer_age", "customer_email", "customer_country", "customer_postal_code", "customer_pet_type", "customer_pet_name", "customer_pet_breed", "seller_first_name", "seller_last_name", "seller_email", "seller_country", "seller_postal_code", "product_name", "product_category", "product_price", "product_quantity", "sale_date", "sale_customer_id", "sale_seller_id", "sale_product_id", "sale_quantity", "sale_total_price", "store_name", "store_location", "store_city", "store_state", "store_country", "store_phone", "store_email", "pet_category", "product_weight", "product_color", "product_size", "product_brand", "product_material", "product_description", "product_rating", "product_reviews", "product_release_date", "product_expiry_date", "supplier_name", "supplier_contact", "supplier_email", "supplier_phone", "supplier_address", "supplier_city", "supplier_country") FROM '/data/MOCK_DATA (1).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY public.mock_data ("id", "customer_first_name", "customer_last_name", "customer_age", "customer_email", "customer_country", "customer_postal_code", "customer_pet_type", "customer_pet_name", "customer_pet_breed", "seller_first_name", "seller_last_name", "seller_email", "seller_country", "seller_postal_code", "product_name", "product_category", "product_price", "product_quantity", "sale_date", "sale_customer_id", "sale_seller_id", "sale_product_id", "sale_quantity", "sale_total_price", "store_name", "store_location", "store_city", "store_state", "store_country", "store_phone", "store_email", "pet_category", "product_weight", "product_color", "product_size", "product_brand", "product_material", "product_description", "product_rating", "product_reviews", "product_release_date", "product_expiry_date", "supplier_name", "supplier_contact", "supplier_email", "supplier_phone", "supplier_address", "supplier_city", "supplier_country") FROM '/data/MOCK_DATA (2).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY public.mock_data ("id", "customer_first_name", "customer_last_name", "customer_age", "customer_email", "customer_country", "customer_postal_code", "customer_pet_type", "customer_pet_name", "customer_pet_breed", "seller_first_name", "seller_last_name", "seller_email", "seller_country", "seller_postal_code", "product_name", "product_category", "product_price", "product_quantity", "sale_date", "sale_customer_id", "sale_seller_id", "sale_product_id", "sale_quantity", "sale_total_price", "store_name", "store_location", "store_city", "store_state", "store_country", "store_phone", "store_email", "pet_category", "product_weight", "product_color", "product_size", "product_brand", "product_material", "product_description", "product_rating", "product_reviews", "product_release_date", "product_expiry_date", "supplier_name", "supplier_contact", "supplier_email", "supplier_phone", "supplier_address", "supplier_city", "supplier_country") FROM '/data/MOCK_DATA (3).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY public.mock_data ("id", "customer_first_name", "customer_last_name", "customer_age", "customer_email", "customer_country", "customer_postal_code", "customer_pet_type", "customer_pet_name", "customer_pet_breed", "seller_first_name", "seller_last_name", "seller_email", "seller_country", "seller_postal_code", "product_name", "product_category", "product_price", "product_quantity", "sale_date", "sale_customer_id", "sale_seller_id", "sale_product_id", "sale_quantity", "sale_total_price", "store_name", "store_location", "store_city", "store_state", "store_country", "store_phone", "store_email", "pet_category", "product_weight", "product_color", "product_size", "product_brand", "product_material", "product_description", "product_rating", "product_reviews", "product_release_date", "product_expiry_date", "supplier_name", "supplier_contact", "supplier_email", "supplier_phone", "supplier_address", "supplier_city", "supplier_country") FROM '/data/MOCK_DATA (4).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY public.mock_data ("id", "customer_first_name", "customer_last_name", "customer_age", "customer_email", "customer_country", "customer_postal_code", "customer_pet_type", "customer_pet_name", "customer_pet_breed", "seller_first_name", "seller_last_name", "seller_email", "seller_country", "seller_postal_code", "product_name", "product_category", "product_price", "product_quantity", "sale_date", "sale_customer_id", "sale_seller_id", "sale_product_id", "sale_quantity", "sale_total_price", "store_name", "store_location", "store_city", "store_state", "store_country", "store_phone", "store_email", "pet_category", "product_weight", "product_color", "product_size", "product_brand", "product_material", "product_description", "product_rating", "product_reviews", "product_release_date", "product_expiry_date", "supplier_name", "supplier_contact", "supplier_email", "supplier_phone", "supplier_address", "supplier_city", "supplier_country") FROM '/data/MOCK_DATA (5).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY public.mock_data ("id", "customer_first_name", "customer_last_name", "customer_age", "customer_email", "customer_country", "customer_postal_code", "customer_pet_type", "customer_pet_name", "customer_pet_breed", "seller_first_name", "seller_last_name", "seller_email", "seller_country", "seller_postal_code", "product_name", "product_category", "product_price", "product_quantity", "sale_date", "sale_customer_id", "sale_seller_id", "sale_product_id", "sale_quantity", "sale_total_price", "store_name", "store_location", "store_city", "store_state", "store_country", "store_phone", "store_email", "pet_category", "product_weight", "product_color", "product_size", "product_brand", "product_material", "product_description", "product_rating", "product_reviews", "product_release_date", "product_expiry_date", "supplier_name", "supplier_contact", "supplier_email", "supplier_phone", "supplier_address", "supplier_city", "supplier_country") FROM '/data/MOCK_DATA (6).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY public.mock_data ("id", "customer_first_name", "customer_last_name", "customer_age", "customer_email", "customer_country", "customer_postal_code", "customer_pet_type", "customer_pet_name", "customer_pet_breed", "seller_first_name", "seller_last_name", "seller_email", "seller_country", "seller_postal_code", "product_name", "product_category", "product_price", "product_quantity", "sale_date", "sale_customer_id", "sale_seller_id", "sale_product_id", "sale_quantity", "sale_total_price", "store_name", "store_location", "store_city", "store_state", "store_country", "store_phone", "store_email", "pet_category", "product_weight", "product_color", "product_size", "product_brand", "product_material", "product_description", "product_rating", "product_reviews", "product_release_date", "product_expiry_date", "supplier_name", "supplier_contact", "supplier_email", "supplier_phone", "supplier_address", "supplier_city", "supplier_country") FROM '/data/MOCK_DATA (7).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY public.mock_data ("id", "customer_first_name", "customer_last_name", "customer_age", "customer_email", "customer_country", "customer_postal_code", "customer_pet_type", "customer_pet_name", "customer_pet_breed", "seller_first_name", "seller_last_name", "seller_email", "seller_country", "seller_postal_code", "product_name", "product_category", "product_price", "product_quantity", "sale_date", "sale_customer_id", "sale_seller_id", "sale_product_id", "sale_quantity", "sale_total_price", "store_name", "store_location", "store_city", "store_state", "store_country", "store_phone", "store_email", "pet_category", "product_weight", "product_color", "product_size", "product_brand", "product_material", "product_description", "product_rating", "product_reviews", "product_release_date", "product_expiry_date", "supplier_name", "supplier_contact", "supplier_email", "supplier_phone", "supplier_address", "supplier_city", "supplier_country") FROM '/data/MOCK_DATA (8).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY public.mock_data ("id", "customer_first_name", "customer_last_name", "customer_age", "customer_email", "customer_country", "customer_postal_code", "customer_pet_type", "customer_pet_name", "customer_pet_breed", "seller_first_name", "seller_last_name", "seller_email", "seller_country", "seller_postal_code", "product_name", "product_category", "product_price", "product_quantity", "sale_date", "sale_customer_id", "sale_seller_id", "sale_product_id", "sale_quantity", "sale_total_price", "store_name", "store_location", "store_city", "store_state", "store_country", "store_phone", "store_email", "pet_category", "product_weight", "product_color", "product_size", "product_brand", "product_material", "product_description", "product_rating", "product_reviews", "product_release_date", "product_expiry_date", "supplier_name", "supplier_contact", "supplier_email", "supplier_phone", "supplier_address", "supplier_city", "supplier_country") FROM '/data/MOCK_DATA (9).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY public.mock_data ("id", "customer_first_name", "customer_last_name", "customer_age", "customer_email", "customer_country", "customer_postal_code", "customer_pet_type", "customer_pet_name", "customer_pet_breed", "seller_first_name", "seller_last_name", "seller_email", "seller_country", "seller_postal_code", "product_name", "product_category", "product_price", "product_quantity", "sale_date", "sale_customer_id", "sale_seller_id", "sale_product_id", "sale_quantity", "sale_total_price", "store_name", "store_location", "store_city", "store_state", "store_country", "store_phone", "store_email", "pet_category", "product_weight", "product_color", "product_size", "product_brand", "product_material", "product_description", "product_rating", "product_reviews", "product_release_date", "product_expiry_date", "supplier_name", "supplier_contact", "supplier_email", "supplier_phone", "supplier_address", "supplier_city", "supplier_country") FROM '/data/MOCK_DATA.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
SELECT COUNT(*) AS imported_rows FROM public.mock_data;
