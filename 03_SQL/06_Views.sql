
--   =================================================================
--   PROJECT 2: MULTI-BRANCH RETAIL PERFORMANCE & REVENUE INTELLIGENCE
--   DATABASE: MySQL 8.0
--   FILE: 06_Views.SQL
--   PURPOSE:
--   	Create reusable analytical views for:
-- 		1. SQL reporting
-- 		2. Power BI integration
-- 		3. KPI calculation
-- 		4. Store, product and customer analysis
--   =================================================================


USE retail_analysis;


--   ============================================================================================
--   VIEW 1: vw_sales_detail
--   ============================================================================================
--   PURPOSE: Create the core transaction-level analytical view.
--   GRAIN: One row per ORDER ITEM.
--   This view combines: orders, order_items, customers, products, categories, stores, promotions
-- 		It intentionally does NOT directly join returns because multiple return records may 
-- 		reference one order_item_id, which could duplicate sales rows.

DROP VIEW IF EXISTS vw_sales_detail;

CREATE VIEW vw_sales_detail AS
SELECT
 
 -- ORDER ITEM
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    oi.qty,
    oi.price,
    ROUND(
        oi.qty * oi.price,
        2
    ) AS gross_sales,

    -- ORDER
    o.customer_id,
    o.store_id,
    o.employee_id,
    o.promotion_id,
    o.order_date,

    -- DATE ATTRIBUTES
    YEAR(o.order_date)
        AS order_year,
    MONTH(o.order_date)
        AS order_month_number,
    MONTHNAME(o.order_date)
        AS order_month,
    QUARTER(o.order_date)
        AS order_quarter,
    DAYNAME(o.order_date)
        AS order_day,

    -- CUSTOMER
    c.customer_name,
    c.city
        AS customer_city,

    -- PRODUCT
    p.product_name,
    p.category_id,
    cat.category_name,

    -- STORE
    s.city
        AS store_city,

    -- PROMOTION
    CASE
        WHEN o.promotion_id IS NULL
            THEN 'No Promotion'
        ELSE 'Promotion'
    END AS promotion_status,
    pr.discount
        AS promotion_discount
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN categories cat
    ON p.category_id = cat.category_id
JOIN stores s
    ON o.store_id = s.store_id
LEFT JOIN promotions pr
    ON o.promotion_id = pr.promotion_id;
    
 
--   ============================================================
--   VALIDATION 1
--   View created successfully

SELECT *
FROM vw_sales_detail
LIMIT 10;


--   ============================================================
--   VALIDATION 2
--   Row count must match order_items

SELECT
    (SELECT COUNT(*)
     FROM order_items)
        AS order_items_rows,
    (SELECT COUNT(*)
     FROM vw_sales_detail)
        AS view_rows;


--   ============================================================
--   VALIDATION 3
--   Gross sales must match source calculation

SELECT
    ROUND(
        SUM(qty * price),
        2
    ) AS source_gross_sales

FROM order_items;

SELECT
    ROUND(
        SUM(gross_sales),
        2
    ) AS view_gross_sales
FROM vw_sales_detail;


--   ============================================================
--   VALIDATION 4
--   Check uniqueness at order-item grain

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_item_id)
        AS unique_order_items,
    COUNT(*) -
    COUNT(DISTINCT order_item_id)
        AS duplicate_rows
FROM vw_sales_detail;


--   ===================================================================
--   VIEW 2: vw_order_summary
--   ===================================================================
--   GRAIN: One row per order_id
--   PURPOSE: Creates an order-level analytical view by aggregating 
-- 		order-item activity to the order level.
--   IMPORTANT: Sales are aggregated BEFORE joining to orders.
-- 		This preserves one row per order and prevents row multiplication.

DROP VIEW IF EXISTS vw_order_summary;

CREATE VIEW vw_order_summary AS
SELECT
    o.order_id,
    o.customer_id,
    o.store_id,
    o.order_date,
    o.promotion_id,

    -- Date attributes
    YEAR(o.order_date) AS order_year,
    QUARTER(o.order_date) AS order_quarter,
    MONTH(o.order_date) AS order_month_number,
    MONTHNAME(o.order_date) AS order_month,

    -- Order metrics
    oi.total_line_items,
    oi.total_quantity,
    oi.order_gross_sales
FROM orders o
JOIN
(
    SELECT
        order_id,
        COUNT(*) AS total_line_items,
        SUM(qty) AS total_quantity,
        ROUND(SUM(qty * price), 2) AS order_gross_sales
    FROM order_items
    GROUP BY order_id
) oi
    ON o.order_id = oi.order_id;
    
    
--   ============================================================
--   VALIDATION 1
--   View created successfully

SELECT *
FROM vw_order_summary
LIMIT 10;


--   ============================================================
--   VALIDATION 2
--   grain/duplicates

SELECT
    COUNT(*) AS view_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM vw_order_summary;


--   ============================================================
--   VALIDATION 3
--   Compare source orders vs view

SELECT
    (SELECT COUNT(DISTINCT order_id)
     FROM order_items) AS source_orders_with_items,
    (SELECT COUNT(*)
     FROM vw_order_summary) AS view_orders;


--   ============================================================
--   VALIDATION 4
--   View created successfully

SELECT
    ROUND(SUM(qty * price), 2) AS source_gross_sales
FROM order_items;

SELECT
    ROUND(SUM(order_gross_sales), 2) AS view_gross_sales
FROM vw_order_summary;


--   ============================================================
--   VALIDATION 5
--   Quantity reconciliation

SELECT
    SUM(qty) AS source_total_quantity
FROM order_items;

SELECT
    SUM(total_quantity) AS view_total_quantity
FROM vw_order_summary;


--   =================================================================================================
--   VIEW 3: vw_store_performance
--   =================================================================================================
--   GRAIN: One row per store_id
--   PURPOSE: Creates a store-level performance view for comparing sales, orders, customers, 
-- 		quantity sold, and average order value across branches.
--   SOURCE: vw_order_summary (validated order-level view) stores
--   IMPORTANT: Gross sales represents sales value before refunds.
-- 		It must NOT be interpreted as profit because product cost / COGS is unavailable in the dataset.

DROP VIEW IF EXISTS vw_store_performance;

CREATE VIEW vw_store_performance AS
SELECT
    s.store_id,
    s.city,
    COUNT(v.order_id) AS total_orders,
    COUNT(DISTINCT v.customer_id) AS unique_customers,
    COALESCE(SUM(v.total_quantity), 0) AS total_quantity,
    COALESCE(
        ROUND(SUM(v.order_gross_sales), 2),
        0.00
    ) AS gross_sales,
    COALESCE(
        ROUND(AVG(v.order_gross_sales), 2),
        0.00
    ) AS avg_order_value
FROM stores s
LEFT JOIN vw_order_summary v
    ON s.store_id = v.store_id
GROUP BY
    s.store_id,
    s.city;


--   ============================================================
--   VALIDATION 1
--   Inspect the view

SELECT *
FROM vw_store_performance
ORDER BY gross_sales DESC
LIMIT 10;


--   ============================================================
--   VALIDATION 2
--   Prove the grain

SELECT
    COUNT(*) AS view_rows,
    COUNT(DISTINCT store_id) AS distinct_stores,
    COUNT(*) - COUNT(DISTINCT store_id) AS duplicate_stores
FROM vw_store_performance;


--   ============================================================
--   VALIDATION 3
--   Source stores vs view

SELECT
    (SELECT COUNT(*)
     FROM stores) AS source_stores,
    (SELECT COUNT(*)
     FROM vw_store_performance) AS view_stores;


--   ============================================================
--   VALIDATION 4
--   Gross-sales reconciliation

SELECT
    ROUND(SUM(order_gross_sales), 2) AS source_gross_sales
FROM vw_order_summary;

SELECT
    ROUND(SUM(gross_sales), 2) AS view_gross_sales
FROM vw_store_performance;


--   ============================================================
--   VALIDATION 5
--   Order reconciliation

SELECT
    COUNT(*) AS source_total_orders
FROM vw_order_summary;

SELECT
    SUM(total_orders) AS view_total_orders
FROM vw_store_performance;


--   ============================================================
--   VALIDATION 6
--   Quantity reconciliation

SELECT
    SUM(total_quantity) AS source_total_quantity
FROM vw_order_summary;

SELECT
    SUM(total_quantity) AS view_total_quantity
FROM vw_store_performance;


--   =============================================================
--   VIEW 4: vw_product_performance
--   =============================================================
--   GRAIN: One row per product_id
--   PURPOSE: Creates a product-level performance view to generate 
-- 		most sales, volumn, and customer demand.


DROP VIEW IF EXISTS vw_product_performance;

CREATE VIEW vw_product_performance AS
SELECT
    p.product_id,
    p.category_id,
    p.supplier_id,
    p.price AS product_price,
    COUNT(DISTINCT sd.order_id) AS total_orders,
    COUNT(DISTINCT sd.customer_id) AS unique_customers,
    SUM(sd.qty) AS total_quantity,
    ROUND(SUM(sd.gross_sales), 2) AS gross_sales,
    ROUND(
        SUM(sd.gross_sales) /
        NULLIF(COUNT(DISTINCT sd.order_id), 0),
        2
    ) AS avg_order_value
FROM products p
LEFT JOIN vw_sales_detail sd
    ON p.product_id = sd.product_id
GROUP BY
    p.product_id,
    p.category_id,
    p.supplier_id,
    p.price;


--   ============================================================
--   VALIDATION 1
--   Inspect the view

SELECT *
FROM vw_product_performance
ORDER BY gross_sales DESC
LIMIT 10;


--   ============================================================
--   VALIDATION 2
--   Grain / duplicate check

SELECT
    COUNT(*) AS view_rows,
    COUNT(DISTINCT product_id) AS distinct_products,
    COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_products
FROM vw_product_performance;


--   ============================================================
--   VALIDATION 3
--   Product coverage

SELECT
    (SELECT COUNT(*)
     FROM products) AS source_products,
    (SELECT COUNT(*)
     FROM vw_product_performance) AS view_products;


--   ============================================================
--   VALIDATION 4
--   Gross sales reconciliation

SELECT
    ROUND(SUM(qty * price), 2) AS source_gross_sales
FROM order_items;

SELECT
    ROUND(SUM(gross_sales), 2) AS view_gross_sales
FROM vw_product_performance;


--   ============================================================
--   VALIDATION 5
--   Quantity reconciliation

SELECT
    SUM(qty) AS source_total_quantity
FROM order_items;

SELECT
    SUM(total_quantity) AS view_total_quantity
FROM vw_product_performance;


--   ============================================================
--   VALIDATION 6
--   Check products with no sales
SELECT
    COUNT(*) AS products_without_sales
FROM vw_product_performance
WHERE total_orders = 0;


--   ====================================================================================
--   VIEW 5: vw_customer_performance
--   ====================================================================================
--   Grain: One row per customer
--   PURPOSE: Creates a reusable customer-level analytical view for customer value,
-- 		purchasing frequency, sales contribution, quantity purchased, and order activity.
--   SOURCE: customers, vw_order_summary
--   IMPORTANT: signup_date is intentionally excluded because the data-quality audit 
-- 		identified orders occurring before recorded customer signup dates.

DROP VIEW IF EXISTS vw_customer_performance;

CREATE VIEW vw_customer_performance AS
SELECT
    c.customer_id,
    c.city,
    COUNT(os.order_id) AS total_orders,
    COALESCE(
        SUM(os.total_quantity),
        0
    ) AS total_quantity,
    COALESCE(
        ROUND(SUM(os.order_gross_sales), 2),
        0.00
    ) AS gross_sales,
    COALESCE(
        ROUND(AVG(os.order_gross_sales), 2),
        0.00
    ) AS avg_order_value,
    MIN(os.order_date) AS first_order_date,
    MAX(os.order_date) AS last_order_date
FROM customers c
LEFT JOIN vw_order_summary os
    ON c.customer_id = os.customer_id
GROUP BY
    c.customer_id,
    c.city;


--   ============================================================
--   VALIDATION 1
--   Inspect the view

SELECT *
FROM vw_customer_performance
ORDER BY gross_sales DESC
LIMIT 10;


--   ============================================================
--   VALIDATION 2
--   Row count + duplicate customer check

SELECT
    COUNT(*) AS view_rows,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customers
FROM vw_customer_performance;


--   ============================================================
--   VALIDATION 3
--   Source customer coverage

SELECT
    (SELECT COUNT(*)
     FROM customers) AS source_customers,
    (SELECT COUNT(*)
     FROM vw_customer_performance) AS view_customers;


--   =======================================================================================
--   VALIDATION 4
--   Active vs inactive customers
-- 		This verifies that the LEFT JOIN preserved customers who have never placed an order.

SELECT
    COUNT(*) AS total_customers,
    SUM(CASE
            WHEN total_orders > 0 THEN 1
            ELSE 0
        END) AS active_customers,
    SUM(CASE
            WHEN total_orders = 0 THEN 1
            ELSE 0
        END) AS inactive_customers
FROM vw_customer_performance;


--   ============================================================
--   VALIDATION 5
--   Total orders reconciliation
--   Since vw_order_summary has one row per order:
-- 		SUM(total_orders) from customer view
-- 		must equal COUNT(*) from order summary.

SELECT
    (SELECT COUNT(*)
     FROM vw_order_summary) AS source_total_orders,
    (SELECT SUM(total_orders)
     FROM vw_customer_performance) AS view_total_orders;


--   ============================================================
--   VALIDATION 6
--   Total quantity reconciliation

SELECT
    (SELECT SUM(total_quantity)
     FROM vw_order_summary) AS source_total_quantity,
    (SELECT SUM(total_quantity)
     FROM vw_customer_performance) AS view_total_quantity;


--   ============================================================
--   VALIDATION 7
--   Gross sales reconciliation

SELECT
    (SELECT ROUND(SUM(order_gross_sales), 2)
     FROM vw_order_summary) AS source_gross_sales,
    (SELECT ROUND(SUM(gross_sales), 2)
     FROM vw_customer_performance) AS view_gross_sales;


--   ============================================================
--   VALIDATION 8
--   Check inactive customer values

SELECT *
FROM vw_customer_performance
WHERE total_orders = 0
LIMIT 10;


--   ==============================================================
--   VALIDATION 9
--   Logical date check
--   Impossible result would be: first_order_date > last_order_date

SELECT
    COUNT(*) AS invalid_order_date_ranges
FROM vw_customer_performance
WHERE first_order_date > last_order_date;


--   ============================================================
--   VALIDATION 10
--   NULL / impossible metric check

SELECT
    COUNT(*) AS invalid_metric_rows
FROM vw_customer_performance
WHERE total_orders IS NULL
   OR total_quantity IS NULL
   OR gross_sales IS NULL
   OR avg_order_value IS NULL
   OR total_orders < 0
   OR total_quantity < 0
   OR gross_sales < 0;


--   ====================================================================================================
--   VALIDATION 11
--   AOV mathematical check
--   gross_sales / total_orders should equal avg_order_value allowing 0.01 difference because of rounding.

SELECT
    COUNT(*) AS aov_mismatch_rows
FROM vw_customer_performance
WHERE total_orders > 0
  AND ABS(
        avg_order_value -
        ROUND(gross_sales / total_orders, 2)
      ) > 0.01;


--   ============================================================
--   VIEW 6: vw_category_performance
--   ============================================================
--   Grain: One row per category
--   PURPOSE: Summarizes product performance at category level.
--   SOURCE: categories, vw_product_performance (validated View 4)

DROP VIEW IF EXISTS vw_category_performance;

CREATE VIEW vw_category_performance AS
SELECT
    c.category_id,
    c.category_name,
    COUNT(pp.product_id) AS total_products,
    COALESCE(
        SUM(pp.total_orders),
        0
    ) AS product_order_occurrences,
    COALESCE(
        SUM(pp.total_quantity),
        0
    ) AS total_quantity,
    COALESCE(
        ROUND(SUM(pp.gross_sales), 2),
        0.00
    ) AS gross_sales
FROM categories c
LEFT JOIN vw_product_performance pp
    ON c.category_id = pp.category_id
GROUP BY
    c.category_id,
    c.category_name;


--   ============================================================
--   VALIDATION 1
--   Inspect the view

SELECT *
FROM vw_category_performance
ORDER BY gross_sales DESC
LIMIT 10;


--   ============================================================
--   VALIDATION 2
--   Row count + duplicate category check

SELECT
    COUNT(*) AS view_rows,
    COUNT(DISTINCT category_id) AS distinct_categories,
    COUNT(*) - COUNT(DISTINCT category_id) AS duplicate_categories
FROM vw_category_performance;


--   ============================================================
--   VALIDATION 3
--   Source category coverage

SELECT
    (SELECT COUNT(*)
     FROM categories) AS source_categories,
    (SELECT COUNT(*)
     FROM vw_category_performance) AS view_categories;


--   ============================================================
--   VALIDATION 4
--   Product reconciliation

SELECT
    (SELECT COUNT(*)
     FROM products) AS source_products,
    (SELECT SUM(total_products)
     FROM vw_category_performance) AS category_view_products;


--   ============================================================
--   VALIDATION 5
--   Product-order-occurrence reconciliation
--   IMPORTANT: This is NOT unique retail orders.
-- 		It is the sum of product-level order counts from View 4.
-- 		Both values must match.

SELECT
    (SELECT SUM(total_orders)
     FROM vw_product_performance) AS source_product_order_occurrences,
    (SELECT SUM(product_order_occurrences)
     FROM vw_category_performance) AS view_product_order_occurrences;


--   ============================================================
--   VALIDATION 6
--   Total quantity reconciliation
--   Both values must match.

SELECT
    (SELECT SUM(total_quantity)
     FROM vw_product_performance) AS source_total_quantity,
    (SELECT SUM(total_quantity)
     FROM vw_category_performance) AS view_total_quantity;


--   ============================================================
--   VALIDATION 7
--   Gross sales reconciliation
--   Both values must match.

SELECT
    (SELECT ROUND(SUM(gross_sales), 2)
     FROM vw_product_performance) AS source_gross_sales,
    (SELECT ROUND(SUM(gross_sales), 2)
     FROM vw_category_performance) AS view_gross_sales;


-- ============================================================
-- VALIDATION 8
-- Categories with zero products

SELECT
    COUNT(*) AS categories_without_products
FROM vw_category_performance
WHERE total_products = 0;


--   ==================================================================
--   VALIDATION 9
--   Check for products whose category does not exist
--   This checks referential integrity between products and categories.

SELECT
    COUNT(*) AS products_with_invalid_category
FROM products p
LEFT JOIN categories c
    ON p.category_id = c.category_id
WHERE c.category_id IS NULL;


--   ============================================================
--   VALIDATION 10
--   Invalid / NULL metric check

SELECT
    COUNT(*) AS invalid_metric_rows
FROM vw_category_performance
WHERE total_products IS NULL
   OR product_order_occurrences IS NULL
   OR total_quantity IS NULL
   OR gross_sales IS NULL
   OR total_products < 0
   OR product_order_occurrences < 0
   OR total_quantity < 0
   OR gross_sales < 0;


--   =============================================================================
--   VALIDATION 11
--   Category product distribution sanity check
--   This is inspection, not pass/fail. Shows smallest and largest category sizes.

SELECT
    MIN(total_products) AS min_products_per_category,
    MAX(total_products) AS max_products_per_category,
    ROUND(AVG(total_products), 2) AS avg_products_per_category
FROM vw_category_performance;




/* ======================= END OF FILE ======================== */