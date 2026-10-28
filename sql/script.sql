-- Create the schema for the Kenya retail analytics
CREATE schema retail;

-- Set the default schema for this session
SET search_path TO retail;

--Verify that the schema exists
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'retail';

--Create the customers table
CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    gender TEXT,
    date_of_birth DATE,
    phone TEXT,
    email TEXT,
    county TEXT,
    signup_date DATE,
    preferred_payment TEXT,
    loyalty_member BOOLEAN,
    age INTEGER,
    age_band TEXT,
    tenure_days INTEGER,
    has_email BOOLEAN
);

select * from customers;

--Create the products table
CREATE TABLE products (
    product_id TEXT PRIMARY KEY,
    product_name TEXT,
    category TEXT,
    subcategory TEXT,
    brand TEXT,
    unit_cost_kes NUMERIC(12,2),
    unit_price_kes NUMERIC(12,2),
    supplier TEXT,
    is_perishable BOOLEAN,
    margin_pct NUMERIC(8,2)
);

select * from products;

-- Create the stores table
CREATE TABLE stores (
    store_id TEXT PRIMARY KEY,
    store_name TEXT,
    county TEXT,
    town TEXT,
    store_type TEXT,
    opening_date DATE,
    floor_area_sqm INTEGER,
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    manager_name TEXT
);

select * from stores;

--Create the promotions table
CREATE TABLE promotions (
    promo_id TEXT PRIMARY KEY,
    promo_name TEXT,
    start_date DATE,
    end_date DATE,
    discount_pct INTEGER,
    category_targeted TEXT,
    duration_days INTEGER
);

select * from promotions;

--Create the KNBS county population table
CREATE TABLE knbs (
    county_name TEXT PRIMARY KEY,
    total_population_2019 BIGINT,
    male_population_2019 BIGINT,
    female_population_2019 BIGINT,
    households BIGINT,
    average_household_size NUMERIC(10,2),
    land_area NUMERIC(12,2),
    population_density BIGINT,
    population_2009 BIGINT,
    population_change BIGINT,
    intersex_population_2019 BIGINT
);

select * from knbs;

--Create the transactions table
CREATE TABLE transactions (
    transaction_id BIGINT PRIMARY KEY,
    invoice_no TEXT NOT NULL,
    transaction_date DATE,
    store_id TEXT NOT NULL REFERENCES stores(store_id),
    customer_id TEXT REFERENCES customers(customer_id),
    product_id TEXT NOT NULL REFERENCES products(product_id),
    quantity INTEGER,
    unit_price_kes NUMERIC(12,2),
    discount_pct INTEGER,
    promo_id TEXT REFERENCES promotions(promo_id),
    payment_method TEXT,
    line_total_kes NUMERIC(14,2),
    channel TEXT,
    date_imputed BOOLEAN,
    year INTEGER,
    outlier_fixed BOOLEAN,
    is_walkin BOOLEAN,
    is_return BOOLEAN,
    on_promo BOOLEAN,
    month INTEGER,
    day_of_week TEXT,
    is_weekend BOOLEAN,
    is_payday_period BOOLEAN
);

select * from transactions;

--Verify that all six tables exist
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'retail'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

--Import the data/tables
-- Database Validation
--1) Table row counts
SELECT 'stores' AS table_name, COUNT(*) AS row_count
FROM stores
UNION ALL
SELECT 'products', COUNT(*)
FROM products
UNION ALL
SELECT 'promotions', COUNT(*)
FROM promotions
UNION ALL
SELECT 'customers', COUNT(*)
FROM customers
UNION ALL
SELECT 'transactions', COUNT(*)
FROM transactions
UNION ALL
SELECT 'knbs', COUNT(*)
FROM knbs;

-- Assessing the quality of the Imported data for Transactions table
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE transaction_id IS NULL
    ) AS missing_transaction_ids,
    COUNT(*) FILTER (
        WHERE transaction_date IS NULL
    ) AS missing_dates,
    COUNT(*) FILTER (
        WHERE store_id IS NULL
    ) AS missing_store_ids,
    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_product_ids,
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_ids,
    COUNT(*) FILTER (
        WHERE promo_id IS NULL
    ) AS missing_promotion_ids
from transactions;

-- 2) Relationships and Unmatched Ids
SELECT
    COUNT(*) FILTER (
        WHERE s.store_id IS NULL
    ) AS unmatched_stores,
    COUNT(*) FILTER (
        WHERE p.product_id IS NULL
    ) AS unmatched_products,
    COUNT(*) FILTER (
        WHERE t.customer_id IS NOT NULL
          AND c.customer_id IS NULL
    ) AS unmatched_customers,
    COUNT(*) FILTER (
        WHERE t.promo_id IS NOT NULL
          AND pr.promo_id IS NULL
    ) AS unmatched_promotions
FROM transactions t
LEFT JOIN stores s
    ON t.store_id = s.store_id
LEFT JOIN products p
    ON t.product_id = p.product_id
LEFT JOIN customers c
    ON t.customer_id = c.customer_id
LEFT JOIN promotions pr
    ON t.promo_id = pr.promo_id;

--3) Missing Values
SELECT
    'transactions' AS table_name,
    'transaction_date' AS column_name,
    COUNT(*) FILTER (
        WHERE transaction_date IS NULL
    ) AS missing_count
FROM transactions
UNION ALL
SELECT 'transactions', 'store_id',
    COUNT(*) FILTER (WHERE store_id IS NULL)
FROM transactions
UNION ALL
SELECT 'transactions', 'product_id',
    COUNT(*) FILTER (WHERE product_id IS NULL)
FROM transactions
UNION ALL
SELECT 'transactions', 'customer_id',
    COUNT(*) FILTER (WHERE customer_id IS NULL)
FROM transactions
UNION ALL
SELECT 'transactions', 'quantity',
    COUNT(*) FILTER (WHERE quantity IS NULL)
FROM transactions
UNION ALL
SELECT 'transactions', 'unit_price_kes',
    COUNT(*) FILTER (WHERE unit_price_kes IS NULL)
FROM transactions
UNION ALL
SELECT 'transactions', 'line_total_kes',
    COUNT(*) FILTER (WHERE line_total_kes IS NULL)
FROM transactions
UNION ALL
SELECT 'transactions', 'promo_id',
    COUNT(*) FILTER (WHERE promo_id IS NULL)
FROM transactions
UNION ALL
SELECT 'customers', 'customer_id',
    COUNT(*) FILTER (WHERE customer_id IS NULL)
FROM customers
UNION ALL
SELECT 'products', 'product_id',
    COUNT(*) FILTER (WHERE product_id IS NULL)
FROM products
UNION ALL
SELECT 'stores', 'store_id',
    COUNT(*) FILTER (WHERE store_id IS NULL)
FROM stores
UNION ALL
SELECT 'promotions', 'promo_id',
    COUNT(*) FILTER (WHERE promo_id IS NULL)
FROM promotions
UNION ALL
SELECT 'knbs', 'county_name',
    COUNT(*) FILTER (WHERE county_name IS NULL)
FROM knbs
ORDER BY table_name, column_name;

--4) Duplicate records identifiers
SELECT
    'transactions' AS table_name,
    'transaction_id' AS identifier,
    COUNT(*) - COUNT(DISTINCT transaction_id)
        AS duplicate_count
FROM transactions
UNION ALL
SELECT
    'stores',
    'store_id',
    COUNT(*) - COUNT(DISTINCT store_id)
FROM stores
UNION ALL
SELECT
    'products',
    'product_id',
    COUNT(*) - COUNT(DISTINCT product_id)
FROM products
UNION ALL
SELECT
    'customers',
    'customer_id',
    COUNT(*) - COUNT(DISTINCT customer_id)
FROM customers
UNION ALL
SELECT
    'promotions',
    'promo_id',
    COUNT(*) - COUNT(DISTINCT promo_id)
FROM promotions
UNION ALL
SELECT
    'knbs',
    'county_name',
    COUNT(*) - COUNT(DISTINCT county_name)
FROM knbs
ORDER BY table_name;

--5) Date coverage 
SELECT
    MIN(transaction_date) AS first_transaction_date,
    MAX(transaction_date) AS last_transaction_date,
    COUNT(DISTINCT transaction_date) AS distinct_transaction_dates,
    COUNT(*) FILTER (
        WHERE transaction_date IS NULL
    ) AS missing_transaction_dates,
    COUNT(*) AS total_transaction_rows
FROM transactions;

--6) Inspecting transaction metric consistency
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE quantity < 0
    ) AS negative_quantity_rows,
    COUNT(*) FILTER (
        WHERE quantity = 0
    ) AS zero_quantity_rows,
    COUNT(*) FILTER (
        WHERE unit_price_kes < 0
    ) AS negative_unit_price_rows,
    COUNT(*) FILTER (
        WHERE line_total_kes < 0
    ) AS negative_line_total_rows,
    COUNT(*) FILTER (
        WHERE discount_pct < 0
           OR discount_pct > 100
    ) AS invalid_discount_rows,
    COUNT(*) FILTER (
        WHERE is_return = TRUE
    ) AS marked_return_rows,
    COUNT(*) FILTER (
        WHERE on_promo = TRUE
    ) AS promotional_rows
FROM transactions;

-- Validate return indicators and signed values
SELECT
    COUNT(*) FILTER (
        WHERE is_return = TRUE
          AND quantity >= 0
    ) AS returns_without_negative_quantity,
    COUNT(*) FILTER (
        WHERE is_return = TRUE
          AND line_total_kes >= 0
    ) AS returns_without_negative_total,
    COUNT(*) FILTER (
        WHERE is_return = FALSE
          AND quantity < 0
    ) AS negative_quantity_not_marked_return,
    COUNT(*) FILTER (
        WHERE is_return = FALSE
          AND line_total_kes < 0
    ) AS negative_total_not_marked_return,
    COUNT(*) FILTER (
        WHERE is_return IS NULL
    ) AS missing_return_indicators
FROM transactions;

-- BUSINESS ANALYSIS
-- A) Overall sales performance
--1) What are the overall sales results?
SELECT
    COUNT(*) AS transaction_lines,
    COUNT(DISTINCT invoice_no) AS unique_invoices,
    SUM(quantity) AS net_units_sold,
    ROUND(SUM(quantity * unit_price_kes), 2)
        AS gross_sales_kes,
    ROUND(SUM(quantity * unit_price_kes - line_total_kes), 2)
        AS net_discount_amount_kes,
    ROUND(SUM(line_total_kes), 2)
        AS net_sales_kes,
    ROUND(
        SUM(line_total_kes) /
        NULLIF(COUNT(DISTINCT invoice_no), 0),
        2
    ) AS average_invoice_value_kes
FROM transactions;

-- Sales and returns
-- 2) How much sales value was reversed by returns?
SELECT
    SUM(CASE
        WHEN is_return = FALSE THEN line_total_kes
        ELSE 0
    END) AS sales_before_returns_kes,
    -SUM(CASE
        WHEN is_return = TRUE THEN line_total_kes
        ELSE 0
    END) AS returned_value_kes,
    SUM(line_total_kes) AS net_sales_kes,
    ROUND(
        100.0 * SUM(CASE
            WHEN is_return = TRUE THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS return_line_percentage
FROM transactions;

-- Sales and discounts before returns
-- 3) What are the original sales value and discounts when returned lines are excluded?
SELECT
    ROUND(
        SUM(quantity * unit_price_kes)
        FILTER (WHERE is_return = FALSE),
        2
    ) AS gross_sales_before_returns_kes,
    ROUND(
        SUM(
            quantity * unit_price_kes - line_total_kes
        ) FILTER (WHERE is_return = FALSE),
        2
    ) AS discounts_before_returns_kes,
    ROUND(
        SUM(line_total_kes)
        FILTER (WHERE is_return = FALSE),
        2
    ) AS sales_before_returns_kes
FROM transactions;

--B) Trends and Seasonality
--Monthly sales performance
-- 1) How do sales change from month to month?
SELECT
    DATE_TRUNC('month', transaction_date)::date AS sales_month,
    ROUND(SUM(line_total_kes), 2) AS net_sales_kes,
    COUNT(DISTINCT invoice_no) AS unique_invoices,
    SUM(quantity) AS net_units_sold
FROM transactions
GROUP BY DATE_TRUNC('month', transaction_date)::date
ORDER BY sales_month;

--Month-over-month sales growth
--2) How do monthly sales change over time?
SELECT
    sales_month,
    net_sales_kes,
    LAG(net_sales_kes) OVER (
        ORDER BY sales_month
    ) AS previous_month_sales_kes,
    ROUND(
        (
            (net_sales_kes - LAG(net_sales_kes) OVER (
                ORDER BY sales_month
            ))
            / NULLIF(
                LAG(net_sales_kes) OVER (
                    ORDER BY sales_month
                ),
                0
            )
        ) * 100,
        2
    ) AS mom_growth_pct
FROM (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS sales_month,
        SUM(line_total_kes) AS net_sales_kes
    FROM transactions
    GROUP BY DATE_TRUNC('month', transaction_date)::date
) monthly_sales
ORDER BY sales_month;

--Year-on-year sales growth
--3) How do sales compare with the same month in the previous year?
SELECT
    sales_month,
    net_sales_kes,
    LAG(net_sales_kes, 12) OVER (
        ORDER BY sales_month
    ) AS same_month_last_year_kes,
    ROUND(
        100.0 * (
            net_sales_kes -
            LAG(net_sales_kes, 12) OVER (
                ORDER BY sales_month
            )
        ) / NULLIF(
            LAG(net_sales_kes, 12) OVER (
                ORDER BY sales_month
            ),
            0
        ),
        2
    ) AS yoy_growth_pct
FROM (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS sales_month,
        SUM(line_total_kes) AS net_sales_kes
    FROM transactions
    GROUP BY DATE_TRUNC('month', transaction_date)::date
) monthly_sales
ORDER BY sales_month;

--Daily sales volatility
--4) How much do sales fluctuate from day to day?
SELECT
    COUNT(*) AS days_with_transactions,
    ROUND(AVG(daily_sales_kes), 2)
        AS average_daily_sales_kes,
    ROUND(STDDEV(daily_sales_kes), 2)
        AS daily_sales_standard_deviation_kes,
    ROUND(MIN(daily_sales_kes), 2)
        AS lowest_daily_sales_kes,
    ROUND(MAX(daily_sales_kes), 2)
        AS highest_daily_sales_kes
FROM (
    SELECT
        transaction_date,
        SUM(line_total_kes) AS daily_sales_kes
    FROM transactions
    GROUP BY transaction_date
) daily_sales;

--Three-month moving average
--5) What is the underlying sales trend after smoothing short-term monthly fluctuations?
SELECT
    sales_month,
    net_sales_kes,
    ROUND(
        AVG(net_sales_kes) OVER (
            ORDER BY sales_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS three_month_moving_average_kes
FROM (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS sales_month,
        SUM(line_total_kes) AS net_sales_kes
    FROM transactions
    GROUP BY DATE_TRUNC('month', transaction_date)::date
) monthly_sales
ORDER BY sales_month;

-- C) Products, Stores and Counties
--Revenue share by category
--1) Which categories contribute most to net sales?
SELECT
    p.category,
    ROUND(SUM(t.line_total_kes), 2) AS net_sales_kes,
    ROUND(
        100.0 * SUM(t.line_total_kes) /
        NULLIF(
            (SELECT SUM(line_total_kes)
             FROM retail.transactions),
            0
        ),
        2
    ) AS revenue_share_pct
FROM transactions t
JOIN retail.products p
    ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY net_sales_kes DESC;

--Rank stores within each county
--2) Which stores perform best in their county?
SELECT
    county,
    store_id,
    store_sales_kes,
    RANK() OVER (
        PARTITION BY county
        ORDER BY store_sales_kes DESC
    ) AS store_rank
FROM (
    SELECT
        s.county,
        s.store_id,
        SUM(t.line_total_kes) AS store_sales_kes
    FROM stores s
    JOIN transactions t
        ON s.store_id = t.store_id
    GROUP BY s.county, s.store_id
) store_sales
ORDER BY county, store_rank;

--County revenue and population
--3) How much net sales is recorded in each county, and what is each county's 2019 population?
SELECT
    s.county,
    ROUND(SUM(t.line_total_kes), 2) AS county_net_sales_kes,
    k.total_population_2019
FROM transactions t
JOIN stores s
    ON t.store_id = s.store_id
JOIN knbs k
    ON LOWER(TRIM(s.county)) = LOWER(TRIM(k.county_name))
GROUP BY s.county, k.total_population_2019
ORDER BY county_net_sales_kes DESC;


-- Revenue per resident
--4) What is recorded county revenue per resident?
SELECT
    s.county,
    ROUND(SUM(t.line_total_kes), 2) AS county_net_sales_kes,
    k.total_population_2019,
    ROUND(
        SUM(t.line_total_kes) /
        NULLIF(k.total_population_2019, 0),
        2
    ) AS revenue_per_resident_kes
FROM transactions t
JOIN stores s
    ON t.store_id = s.store_id
JOIN knbs k
    ON LOWER(TRIM(s.county)) = LOWER(TRIM(k.county_name))
GROUP BY s.county, k.total_population_2019
ORDER BY revenue_per_resident_kes DESC;

--Product sales mix
--5) Which products contribute most to units and revenue?
SELECT
    p.product_name,
    p.category,
    SUM(t.quantity) AS net_units_sold,
    ROUND(SUM(t.line_total_kes), 2) AS net_sales_kes,
    ROUND(
        100.0 * SUM(t.line_total_kes) /
        NULLIF(
            (SELECT SUM(line_total_kes)
             FROM transactions),
            0
        ),
        2
    ) AS revenue_share_pct
FROM transactions t
JOIN products p
    ON t.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY net_sales_kes DESC;

--Top three products per category
--6) Which three products generate the highest net sales within each category?
SELECT
    category,
    product_name,
    net_sales_kes
FROM (
    SELECT
        p.category,
        p.product_name,
        SUM(t.line_total_kes) AS net_sales_kes,
        ROW_NUMBER() OVER (
            PARTITION BY p.category
            ORDER BY SUM(t.line_total_kes) DESC
        ) AS product_rank
    FROM transactions t
    JOIN products p
        ON t.product_id = p.product_id
    GROUP BY
        p.category,
        p.product_id,
        p.product_name
) ranked_products
WHERE product_rank <= 3
ORDER BY category, net_sales_kes DESC;

-- Store type comparison
--7) How do different store types compare in net sales, invoice volume, and average invoice value?
SELECT
    s.store_type,
    ROUND(SUM(t.line_total_kes), 2) AS net_sales_kes,
    COUNT(DISTINCT t.invoice_no) AS unique_invoices,
    ROUND(
        SUM(t.line_total_kes) /
        NULLIF(COUNT(DISTINCT t.invoice_no), 0),
        2
    ) AS average_invoice_value_kes
FROM stores s
JOIN transactions t
    ON s.store_id = t.store_id
GROUP BY s.store_type
ORDER BY net_sales_kes DESC;

--D) Payments and customer value
--Payment method usage
--1) Which payment methods generate the most transactions and net sales?
SELECT
    payment_method,
    COUNT(DISTINCT invoice_no) AS unique_invoices,
    COUNT(*) AS transaction_lines,
    ROUND(SUM(line_total_kes), 2) AS net_sales_kes
FROM transactions
GROUP BY payment_method
ORDER BY net_sales_kes DESC;

--M-Pesa versus other baskets
--2) Do M-Pesa invoices differ in value or size?
SELECT
    CASE
        WHEN LOWER(payment_method) LIKE '%mpesa%'
          OR LOWER(payment_method) LIKE '%m-pesa%'
        THEN 'M-Pesa'
        ELSE 'Other payment methods'
    END AS payment_group,
    COUNT(*) AS invoice_count,
    ROUND(AVG(basket_value_kes), 2) AS average_basket_value_kes,
    ROUND(AVG(basket_units), 2) AS average_basket_units
FROM (
    SELECT
        invoice_no,
        payment_method,
        SUM(line_total_kes) AS basket_value_kes,
        SUM(quantity) AS basket_units
    FROM transactions
    WHERE is_return = FALSE
    GROUP BY invoice_no, payment_method
) baskets
GROUP BY
    CASE
        WHEN LOWER(payment_method) LIKE '%mpesa%'
          OR LOWER(payment_method) LIKE '%m-pesa%'
        THEN 'M-Pesa'
        ELSE 'Other payment methods'
    END
ORDER BY average_basket_value_kes DESC;

--Spend by loyalty membership
--3) Do loyalty members spend differently?
SELECT
    c.loyalty_member,
    COUNT(DISTINCT t.customer_id) AS unique_customers,
    COUNT(DISTINCT t.invoice_no) AS unique_invoices,
    ROUND(SUM(t.line_total_kes), 2) AS net_sales_kes,
    ROUND(
        SUM(t.line_total_kes) /
        NULLIF(COUNT(DISTINCT t.invoice_no), 0),
        2
    ) AS average_invoice_value_kes
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
WHERE t.is_return = FALSE
GROUP BY c.loyalty_member
ORDER BY net_sales_kes DESC;

-- Spend by preferred payment method
--4) How does spending vary by customers' recorded preferred payment method?
SELECT
    c.preferred_payment,
    COUNT(DISTINCT c.customer_id) AS unique_customers,
    COUNT(DISTINCT t.invoice_no) AS unique_invoices,
    ROUND(SUM(t.line_total_kes), 2) AS sales_kes,
    ROUND(
        SUM(t.line_total_kes) /
        NULLIF(COUNT(DISTINCT t.invoice_no), 0),
        2
    ) AS average_invoice_value_kes
FROM customers c
JOIN transactions t
    ON c.customer_id = t.customer_id
WHERE t.is_return = FALSE
GROUP BY c.preferred_payment
ORDER BY sales_kes DESC;

--Average order value
--5) How much does an average invoice generate?
SELECT
    COUNT(*) AS number_of_invoices,
    ROUND(AVG(invoice_value_kes), 2) AS average_order_value_kes,
    ROUND(MIN(invoice_value_kes), 2) AS smallest_invoice_kes,
    ROUND(MAX(invoice_value_kes), 2) AS largest_invoice_kes
FROM (
    SELECT
        invoice_no,
        SUM(line_total_kes) AS invoice_value_kes
    FROM transactions
    WHERE is_return = FALSE
    GROUP BY invoice_no
) invoices;

--Purchase frequency
--6) How often do registered customers buy?
SELECT
    COUNT(DISTINCT customer_id) AS purchasing_customers,
    COUNT(DISTINCT invoice_no) AS unique_invoices,
    ROUND(
        COUNT(DISTINCT invoice_no)::numeric /
        NULLIF(COUNT(DISTINCT customer_id), 0),
        2
    ) AS average_invoices_per_customer
FROM transactions
WHERE customer_id IS NOT NULL
  AND is_return = FALSE;

--E) Customer Cohorts and RFM Segmentation
--Quarterly customer cohorts
--1) What proportion of customers return in subsequent quarters?
WITH customer_quarters AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('quarter', transaction_date)::date AS purchase_quarter
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND is_return = FALSE
),
customer_cohorts AS (
    SELECT
        customer_id,
        MIN(purchase_quarter) AS cohort_quarter
    FROM customer_quarters
    GROUP BY customer_id
)
SELECT
    c.cohort_quarter,
    q.purchase_quarter,
    (
        (EXTRACT(YEAR FROM q.purchase_quarter) -
         EXTRACT(YEAR FROM c.cohort_quarter)) * 4
        + EXTRACT(QUARTER FROM q.purchase_quarter)
        - EXTRACT(QUARTER FROM c.cohort_quarter)
    ) AS quarters_since_first_purchase,
    COUNT(DISTINCT q.customer_id) AS active_customers,
    COUNT(DISTINCT c.customer_id) AS cohort_size,
    ROUND(
        100.0 * COUNT(DISTINCT q.customer_id) /
        NULLIF(COUNT(DISTINCT c.customer_id), 0),
        2
    ) AS retention_pct
FROM customer_cohorts c
JOIN customer_quarters q
    ON c.customer_id = q.customer_id
GROUP BY c.cohort_quarter, q.purchase_quarter
ORDER BY c.cohort_quarter, q.purchase_quarter;

-- RFM scores
--2) How do customers compare in RFM?
WITH customer_rfm AS (
    SELECT
        customer_id,
        CURRENT_DATE - MAX(transaction_date) AS recency_days,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(line_total_kes) AS monetary_kes
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND is_return = FALSE
    GROUP BY customer_id
)
SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary_kes, 2) AS monetary_kes,
    NTILE(5) OVER (
        ORDER BY recency_days DESC
    ) AS recency_score,
    NTILE(5) OVER (
        ORDER BY frequency ASC
    ) AS frequency_score,
    NTILE(5) OVER (
        ORDER BY monetary_kes ASC
    ) AS monetary_score
FROM customer_rfm
ORDER BY monetary_kes DESC;

--RFM segments
--3) How many customers are in each segment, and how much sales value does each segment contribute?
WITH customer_rfm AS (
    SELECT
        customer_id,
        MAX(transaction_date) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(line_total_kes) AS monetary_kes
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND is_return = FALSE
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        last_purchase_date,
        frequency,
        monetary_kes,
        NTILE(5) OVER (
            ORDER BY last_purchase_date ASC
        ) AS recency_score,
        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,
        NTILE(5) OVER (
            ORDER BY monetary_kes ASC
        ) AS monetary_score
    FROM customer_rfm
),
segments AS (
    SELECT *,
        CASE
            WHEN recency_score >= 4
             AND frequency_score >= 4
             AND monetary_score >= 4
                THEN 'Champions'
            WHEN frequency_score >= 4
             AND recency_score >= 3
                THEN 'Loyal customers'
            WHEN recency_score <= 2
             AND frequency_score >= 3
                THEN 'At risk'
            WHEN recency_score >= 4
                THEN 'Recent customers'
            ELSE 'Other customers'
        END AS customer_segment
    FROM rfm_scores
)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(monetary_kes), 2) AS total_sales_kes,
    ROUND(AVG(monetary_kes), 2) AS average_sales_per_customer_kes
FROM segments
GROUP BY customer_segment
ORDER BY total_sales_kes DESC;

--Inactive customer groups
--4) Which customer groups have not purchased in the last 90 days of the dataset?
WITH last_purchase AS (
    SELECT
        customer_id,
        MAX(transaction_date) AS last_purchase_date
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND is_return = FALSE
    GROUP BY customer_id
),
dataset_date AS (
    SELECT MAX(transaction_date) AS latest_date
    FROM transactions
)
SELECT
    c.age_band,
    c.loyalty_member,
    COUNT(*) AS inactive_customers
FROM customers c
JOIN last_purchase p
    ON c.customer_id = p.customer_id
CROSS JOIN dataset_date d
WHERE p.last_purchase_date < d.latest_date - INTERVAL '90 days'
GROUP BY c.age_band, c.loyalty_member
ORDER BY inactive_customers DESC;

--Repeat-purchase rate
--5) What percentage of purchasing customers have made more than one purchase?
SELECT
    COUNT(*) AS purchasing_customers,
    COUNT(*) FILTER (
        WHERE invoice_count > 1
    ) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE invoice_count > 1
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_purchase_rate_pct
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS invoice_count
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND is_return = FALSE
    GROUP BY customer_id
) customer_purchases;

--Quarterly customer retention trend
--6) Is retention improving or declining?
WITH quarterly_customers AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('quarter', transaction_date)::date AS sales_quarter
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND is_return = FALSE
),
quarterly_retention AS (
    SELECT
        previous.sales_quarter + INTERVAL '3 months' AS sales_quarter,
        COUNT(*) AS previous_quarter_customers,
        COUNT(current.customer_id) AS retained_customers
    FROM quarterly_customers previous
    LEFT JOIN quarterly_customers current
        ON previous.customer_id = current.customer_id
       AND current.sales_quarter =
           previous.sales_quarter + INTERVAL '3 months'
    GROUP BY previous.sales_quarter
)
SELECT
    sales_quarter,
    previous_quarter_customers,
    retained_customers,
    ROUND(
        100.0 * retained_customers /
        NULLIF(previous_quarter_customers, 0),
        2
    ) AS retention_rate_pct
FROM quarterly_retention
ORDER BY sales_quarter;

--G) Promotion revenue and discounts
--Promotion revenue and discounts
--1) How much revenue and discount are associated with each promotion?
SELECT
    COALESCE(promo_id, 'No promotion') AS promotion,
    COUNT(DISTINCT invoice_no) AS invoice_count,
    ROUND(SUM(line_total_kes), 2) AS recorded_net_sales_kes,
    ROUND(
        SUM(quantity * unit_price_kes * discount_pct / 100.0),
        2
    ) AS recorded_discount_kes,
    ROUND(AVG(discount_pct), 2) AS average_discount_pct
FROM transactions
GROUP BY promo_id
ORDER BY recorded_net_sales_kes DESC;

--Promotion lift
--2) Was daily revenue higher during a promotion than during the preceding 28 days?
WITH promotion_dates AS (
    SELECT
        promo_id,
        MIN(transaction_date) AS first_promo_date,
        MAX(transaction_date) AS last_promo_date
    FROM transactions
    WHERE promo_id IS NOT NULL
    GROUP BY promo_id
),
daily_sales AS (
    SELECT
        transaction_date,
        SUM(line_total_kes) AS daily_revenue_kes
    FROM retail.transactions
    GROUP BY transaction_date
),
promotion_comparison AS (
    SELECT
        p.promo_id,
        AVG(
            CASE
                WHEN d.transaction_date BETWEEN
                     p.first_promo_date AND p.last_promo_date
                THEN d.daily_revenue_kes
            END
        ) AS promo_daily_revenue,
        AVG(
            CASE
                WHEN d.transaction_date BETWEEN
                     p.first_promo_date - 28 AND p.first_promo_date - 1
                THEN d.daily_revenue_kes
            END
        ) AS previous_28_day_revenue
    FROM promotion_dates p
    JOIN daily_sales d
      ON d.transaction_date BETWEEN
         p.first_promo_date - 28 AND p.last_promo_date
    GROUP BY p.promo_id
)
SELECT
    promo_id,
    ROUND(promo_daily_revenue, 2) AS avg_daily_revenue_during_promo_kes,
    ROUND(previous_28_day_revenue, 2) AS avg_daily_revenue_before_promo_kes,
    ROUND(
        promo_daily_revenue - previous_28_day_revenue,
        2
    ) AS daily_revenue_change_kes,
    ROUND(
        100.0 * (promo_daily_revenue - previous_28_day_revenue)
        / NULLIF(previous_28_day_revenue, 0),
        2
    ) AS revenue_change_pct
FROM promotion_comparison
ORDER BY revenue_change_pct DESC NULLS LAST;

--Promotional versus non-promotional sales
--3) How do sales and average basket values compare?
WITH invoice_sales AS (
    SELECT
        invoice_no,
        BOOL_OR(on_promo) AS used_promotion,
        SUM(line_total_kes) AS basket_value_kes,
        SUM(quantity) AS basket_units
    FROM transactions
    WHERE is_return = FALSE
    GROUP BY invoice_no
)
SELECT
    CASE
        WHEN used_promotion THEN 'Promotional'
        ELSE 'Non-promotional'
    END AS sales_group,
    COUNT(*) AS invoice_count,
    ROUND(SUM(basket_value_kes), 2) AS total_sales_kes,
    ROUND(AVG(basket_value_kes), 2) AS average_basket_value_kes,
    ROUND(AVG(basket_units), 2) AS average_basket_units
FROM invoice_sales
GROUP BY used_promotion
ORDER BY total_sales_kes DESC;

--Return rate by category
--4) Which categories have the highest return rates?
SELECT
    p.category,
    SUM(CASE WHEN t.quantity > 0 THEN t.quantity ELSE 0 END)
        AS units_sold,
    SUM(CASE WHEN t.quantity < 0 THEN ABS(t.quantity) ELSE 0 END)
        AS units_returned,
    ROUND(
        100.0 * SUM(
            CASE WHEN t.quantity < 0 THEN ABS(t.quantity) ELSE 0 END
        ) / NULLIF(
            SUM(CASE WHEN t.quantity > 0 THEN t.quantity ELSE 0 END),
            0
        ),
        2
    ) AS return_rate_pct
FROM transactions t
JOIN retail.products p
    ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY return_rate_pct DESC NULLS LAST;

--Return rate by product
--5) Which individual products have the highest return rates?
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(CASE WHEN t.quantity > 0 THEN t.quantity ELSE 0 END)
        AS units_sold,
    SUM(CASE WHEN t.quantity < 0 THEN ABS(t.quantity) ELSE 0 END)
        AS units_returned,
    ROUND(
        100.0 * SUM(
            CASE WHEN t.quantity < 0 THEN ABS(t.quantity) ELSE 0 END
        ) / NULLIF(
            SUM(CASE WHEN t.quantity > 0 THEN t.quantity ELSE 0 END),
            0
        ),
        2
    ) AS return_rate_pct
FROM transactions t
JOIN products p
    ON t.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
HAVING SUM(CASE WHEN t.quantity > 0 THEN t.quantity ELSE 0 END) > 0
ORDER BY return_rate_pct DESC, units_returned DESC;

--Returns over time
--6) Are returns increasing or decreasing?
SELECT
    DATE_TRUNC('month', transaction_date)::date AS sales_month,
    COUNT(*) AS return_lines,
    SUM(ABS(quantity)) AS units_returned,
    ROUND(ABS(SUM(line_total_kes)), 2) AS return_value_kes
FROM transactions
WHERE is_return = TRUE
GROUP BY DATE_TRUNC('month', transaction_date)::date
ORDER BY sales_month;












