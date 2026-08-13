
--   ==============================================================================================
--   PROJECT: MULTI-BRANCH RETAIL PERFORMANCE & REVENUE INTELLIGENCE
--   DATABASE: MySQL 8.0
--   FILE: 03_Data_Cleaning.sql
--   PURPOSE:
--       Audit data quality, identify invalid or inconsistent records, 
-- 		 apply necessary cleaning rules, Validate foreign-key relationships, 
-- 		 investigate duplicate business relationships, validate shipment statuses & refund amounts, 
--   	 perform final post-cleaning validation and validate the cleaned retail data warehouse.
--   ==============================================================================================

USE retail_dw;

--   ===================================================
--   SECTION 1: PRE-CLEANING ROW COUNTS

SELECT 'categories' AS table_name, COUNT(*) AS row_count
FROM categories
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'stores', COUNT(*) FROM stores
UNION ALL
SELECT 'suppliers', COUNT(*) FROM suppliers
UNION ALL
SELECT 'promotions', COUNT(*) FROM promotions
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'shipments', COUNT(*) FROM shipments
UNION ALL
SELECT 'returns', COUNT(*) FROM returns;

                                                                             
-- 	 ==================================================
--   SECTION 2: PRIMARY KEY DUPLICATE CHECKS
-- 	 These should return zero rows.
-- 	 PK constraints already prevent duplicate PK values,
--   but these queries document the validation process.

SELECT 'categories' AS table_name,
       COUNT(*) AS duplicate_groups
FROM (
    SELECT category_id
    FROM categories
    GROUP BY category_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'customers', COUNT(*)
FROM (
    SELECT customer_id
    FROM customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'stores', COUNT(*)
FROM (
    SELECT store_id
    FROM stores
    GROUP BY store_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'suppliers', COUNT(*)
FROM (
    SELECT supplier_id
    FROM suppliers
    GROUP BY supplier_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'promotions', COUNT(*)
FROM (
    SELECT promotion_id
    FROM promotions
    GROUP BY promotion_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'products', COUNT(*)
FROM (
    SELECT product_id
    FROM products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'employees', COUNT(*)
FROM (
    SELECT employee_id
    FROM employees
    GROUP BY employee_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'orders', COUNT(*)
FROM (
    SELECT order_id
    FROM orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'order_items', COUNT(*)
FROM (
    SELECT order_item_id
    FROM order_items
    GROUP BY order_item_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'payments', COUNT(*)
FROM (
    SELECT payment_id
    FROM payments
    GROUP BY payment_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'shipments', COUNT(*)
FROM (
    SELECT shipment_id
    FROM shipments
    GROUP BY shipment_id
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT 'returns', COUNT(*)
FROM (
    SELECT return_id
    FROM returns
    GROUP BY return_id
    HAVING COUNT(*) > 1
) x;


-- 	 ============================================
--   SECTION 3: NULL VALUE AUDIT
-- 	 All query return values are expected to be 0.

-- categories
SELECT
    SUM(category_id IS NULL) AS null_category_id,
    SUM(category_name IS NULL) AS null_category_name
FROM categories;

-- customers
SELECT
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(city IS NULL) AS null_city,
    SUM(signup_date IS NULL) AS null_signup_date
FROM customers;

-- stores
SELECT
    SUM(store_id IS NULL) AS null_store_id,
    SUM(city IS NULL) AS null_city
FROM stores;

-- suppliers
SELECT
    SUM(supplier_id IS NULL) AS null_supplier_id,
    SUM(country IS NULL) AS null_country
FROM suppliers;

-- promotions
SELECT
    SUM(promotion_id IS NULL) AS null_promotion_id,
    SUM(discount IS NULL) AS null_discount
FROM promotions;

-- products
SELECT
    SUM(product_id IS NULL) AS null_product_id,
    SUM(category_id IS NULL) AS null_category_id,
    SUM(supplier_id IS NULL) AS null_supplier_id,
    SUM(price IS NULL) AS null_price
FROM products;

-- employees
SELECT
    SUM(employee_id IS NULL) AS null_employee_id,
    SUM(store_id IS NULL) AS null_store_id,
    SUM(salary IS NULL) AS null_salary
FROM employees;

-- orders
SELECT
    SUM(order_id IS NULL) AS null_order_id,
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(store_id IS NULL) AS null_store_id,
    SUM(order_date IS NULL) AS null_order_date,
    SUM(promotion_id IS NULL) AS null_promotion_id
FROM orders;

-- order_items
SELECT
    SUM(order_item_id IS NULL) AS null_order_item_id,
    SUM(order_id IS NULL) AS null_order_id,
    SUM(product_id IS NULL) AS null_product_id,
    SUM(qty IS NULL) AS null_qty,
    SUM(price IS NULL) AS null_price
FROM order_items;

-- payments
SELECT
    SUM(payment_id IS NULL) AS null_payment_id,
    SUM(order_id IS NULL) AS null_order_id,
    SUM(amount IS NULL) AS null_amount
FROM payments;

-- shipments
SELECT
    SUM(shipment_id IS NULL) AS null_shipment_id,
    SUM(order_id IS NULL) AS null_order_id,
    SUM(shipment_status IS NULL) AS null_shipment_status
FROM shipments;

-- returns
SELECT
    SUM(return_id IS NULL) AS null_return_id,
    SUM(order_item_id IS NULL) AS null_order_item_id,
    SUM(refund IS NULL) AS null_refund
FROM returns;


--   ============================================================
--   SECTION 4: BLANK STRING AUDIT
--   NULL and blank strings are different.
--   Check textual columns for empty/whitespace-only values.

SELECT *
FROM categories
WHERE TRIM(category_name) = '';

SELECT *
FROM customers
WHERE TRIM(city) = '';

SELECT *
FROM stores
WHERE TRIM(city) = '';

SELECT *
FROM suppliers
WHERE TRIM(country) = '';

SELECT *
FROM shipments
WHERE TRIM(status) = '';


--   ============================================================
--   SECTION 5: STANDARDIZE TEXT VALUES
--   Remove accidental leading/trailing whitespace.

UPDATE categories
SET category_name = TRIM(category_name)
WHERE category_name IS NOT NULL;

UPDATE customers
SET city = TRIM(city)
WHERE city IS NOT NULL;

UPDATE stores
SET city = TRIM(city)
WHERE city IS NOT NULL;

UPDATE suppliers
SET country = TRIM(country)
WHERE country IS NOT NULL;

UPDATE shipments
SET status = TRIM(status)
WHERE status IS NOT NULL;


--   ============================================================
--   SECTION 6: STANDARDIZE SHIPMENT STATUS

-- Convert status values to uppercase.
SET SQL_SAFE_UPDATES = 0;

UPDATE shipments
SET status = UPPER(status)
WHERE status IS NOT NULL;

SET SQL_SAFE_UPDATES = 1;

-- Check standardized values.
SELECT
    status,
    COUNT(*) AS shipment_count
FROM shipments
GROUP BY status
ORDER BY shipment_count DESC;

-- Detect unexpected statuses.
SELECT DISTINCT status
FROM shipments
WHERE status NOT IN ('SHIPPED', 'DELIVERED', 'LATE')
   OR status IS NULL;


--   ============================================================
--   SECTION 7: NUMERIC VALIDATION

-- product.price
SELECT *
FROM products
WHERE price IS NULL
   OR price <= 0;

-- employee.salary
SELECT *
FROM employees
WHERE salary IS NULL
   OR salary <= 0;

-- promotion.discount
-- Validate discount range.
-- Do not automatically assume percentage vs decimal format.
-- First inspect the actual distribution.
SELECT *
FROM promotions
WHERE discount IS NULL
   OR discount < 0;
   
SELECT
    MIN(discount) AS min_discount,
    MAX(discount) AS max_discount,
    AVG(discount) AS avg_discount
FROM promotions;

-- order_items.qty, order_items.price
SELECT *
FROM order_items
WHERE qty IS NULL
   OR qty <= 0;

SELECT *
FROM order_items
WHERE price IS NULL
   OR price <= 0;

-- payments.amount
SELECT *
FROM payments
WHERE amount IS NULL
   OR amount < 0;

-- returns.refund
SELECT *
FROM returns
WHERE refund IS NULL
   OR refund < 0;

-- ============================================================
-- SECTION 8: DATE VALIDATION

-- Customer signup dates
SELECT
    MIN(signup_date) AS earliest_signup,
    MAX(signup_date) AS latest_signup
FROM customers;

-- Order date range.
SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order
FROM orders;

-- Orders occurring before customer signup.
-- Ideally returns zero rows.
SELECT
    o.order_id,
    o.customer_id,
    c.signup_date,
    o.order_date
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date
LIMIT 100;

-- Count the problem separately.
SELECT
    COUNT(*) AS orders_before_customer_signup
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date;

-- ==========================================================================
-- DATA QUALITY DECISION:
--
-- 120,020 orders occur before the associated customer's signup_date.
--
-- Because this affects roughly 40% of the order table dataset,
-- these records will NOT be deleted or artificially corrected.
--
-- order_date will remain valid for transactional/time analysis.
--
-- signup_date will NOT be used to calculate customer tenure,
-- pre/post-signup behaviour, or acquisition-based metrics
-- without accounting for this inconsistency.
--
-- This issue is retained and documented as a source-data quality limitation.
-- ==========================================================================


--  ===========================================================================================================
--  SECTION 9: FOREIGN KEY / ORPHAN RECORD VALIDATION
--  All query should return value 0 otherwise data is inconsitent when trying to matching foreign key reference.

-- Products referencing nonexistent categories
SELECT COUNT(*) AS invalid_product_categories
FROM products p
LEFT JOIN categories c
    ON p.category_id = c.category_id
WHERE c.category_id IS NULL;

-- Products referencing nonexistent suppliers
SELECT COUNT(*) AS invalid_product_suppliers
FROM products p
LEFT JOIN suppliers s
    ON p.supplier_id = s.supplier_id
WHERE s.supplier_id IS NULL;

-- Employees referencing nonexistent stores
SELECT COUNT(*) AS invalid_employee_stores
FROM employees e
LEFT JOIN stores s
    ON e.store_id = s.store_id
WHERE s.store_id IS NULL;

-- Orders referencing nonexistent customers
SELECT COUNT(*) AS invalid_order_customers
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Orders referencing nonexistent stores
SELECT COUNT(*) AS invalid_order_stores
FROM orders o
LEFT JOIN stores s
    ON o.store_id = s.store_id
WHERE s.store_id IS NULL;

-- Order items referencing nonexistent orders
SELECT COUNT(*) AS invalid_orderitem_orders
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order items referencing nonexistent products
SELECT COUNT(*) AS invalid_orderitem_products
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Payments referencing nonexistent orders
SELECT COUNT(*) AS invalid_payment_orders
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Shipments referencing nonexistent orders
SELECT COUNT(*) AS invalid_shipment_orders
FROM shipments s
LEFT JOIN orders o
    ON s.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Returns referencing nonexistent order items
SELECT COUNT(*) AS invalid_return_orderitems
FROM returns r
LEFT JOIN order_items oi
    ON r.order_item_id = oi.order_item_id
WHERE oi.order_item_id IS NULL;


--   ================================================================================
--   SECTION 10: BUSINESS-KEY DUPLICATE INVESTIGATION
-- 	 IMPORTANT: Multiple rows sharing a foreign key are NOT automatically duplicates.
--   Examples:
--     One order can contain multiple order items.
--     Multiple returns can potentially reference the same item.
--   Therefore these are investigated rather than deleted.

-- Multiple payments per order.
SELECT
    order_id,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_paid
FROM payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_count DESC
LIMIT 100;

-- Multiple shipments per order.
SELECT
    order_id,
    COUNT(*) AS shipment_count
FROM shipments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY shipment_count DESC
LIMIT 100;


--   =========================================================================================
--   SECTION 11: RETURNS DUPLICATE RELATIONSHIP INVESTIGATION
--   Previous validation found some order_item_id values appearing more than once in returns.
--   This does NOT mean return_id is duplicated.
--   return_id remains the primary key.
--   Do NOT delete these rows automatically.
--   They may represent multiple legitimate refund transactions.

SELECT
    order_item_id,
    COUNT(*) AS return_count,
    SUM(refund) AS total_refund
FROM returns
GROUP BY order_item_id
HAVING COUNT(*) > 1
ORDER BY return_count DESC, order_item_id;

-- Show detailed records.
SELECT
    r.return_id,
    r.order_item_id,
    r.refund
FROM returns r
JOIN (
    SELECT order_item_id
    FROM returns
    GROUP BY order_item_id
    HAVING COUNT(*) > 1
) d
    ON r.order_item_id = d.order_item_id
ORDER BY r.order_item_id, r.return_id;


--   =====================================================================
--   SECTION 12: REFUND VS ORDER ITEM VALUE VALIDATION
--   Calculate original line value:
--   qty × price
--   Compare total refund against that value.
--   Multiple return records are aggregated first 
--   because the same order_item_id may legitimately appear more than once.

SELECT
    oi.order_item_id,
    oi.qty,
    oi.price,
    (oi.qty * oi.price) AS original_item_value,
    SUM(r.refund) AS total_refund
FROM order_items oi
JOIN returns r
    ON oi.order_item_id = r.order_item_id
GROUP BY
    oi.order_item_id,
    oi.qty,
    oi.price
HAVING SUM(r.refund) > (oi.qty * oi.price)
ORDER BY total_refund DESC
LIMIT 100;

-- Count how many order items have refunds exceeding their original line value.
SELECT
    COUNT(*) AS excessive_refund_items
FROM (
    SELECT
        oi.order_item_id
    FROM order_items oi
    JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY
        oi.order_item_id,
        oi.qty,
        oi.price
    HAVING SUM(r.refund) > (oi.qty * oi.price)
) x;


--   ====================================================================
--   SECTION 13: ORDER ITEM PRICE VS PRODUCT PRICE
--   IMPORTANT: We do NOT overwrite order_items.price with products.price.
--   products.price can represent the product/master price,
--   while order_items.price represents the transaction price.
--   Differences may therefore be analytically meaningful.

SELECT
    COUNT(*) AS price_difference_rows
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
WHERE oi.price <> p.price;

-- Inspect sample differences.
SELECT
    oi.order_item_id,
    oi.product_id,
    oi.price AS transaction_price,
    p.price AS product_price,
    oi.price - p.price AS price_difference
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
WHERE oi.price <> p.price
LIMIT 100;


--   ============================================================
--   SECTION 14: PAYMENT VS ORDER VALUE INVESTIGATION
--   Calculate gross order value from order_items.
--   This is an audit only.
--   Promotion discounts may cause payment amount to differ from gross merchandise value.

WITH order_values AS (
    SELECT
        order_id,
        SUM(qty * price) AS gross_order_value
    FROM order_items
    GROUP BY order_id
),
payment_values AS (
    SELECT
        order_id,
        SUM(amount) AS total_payment
    FROM payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    ov.gross_order_value,
    pv.total_payment,
    pv.total_payment - ov.gross_order_value AS difference
FROM orders o
LEFT JOIN order_values ov
    ON o.order_id = ov.order_id
LEFT JOIN payment_values pv
    ON o.order_id = pv.order_id
WHERE ov.gross_order_value IS NOT NULL
  AND pv.total_payment IS NOT NULL
  AND ABS(pv.total_payment - ov.gross_order_value) > 0.01
LIMIT 100;


--   ============================================================
--   SECTION 15: CATEGORY STANDARDIZATION CHECK

SELECT
    category_name,
    COUNT(*) AS category_count
FROM categories
GROUP BY category_name 
ORDER BY category_name;


--   ============================================================
--   SECTION 16: CUSTOMER CITY STANDARDIZATION CHECK

SELECT
    city,
    COUNT(*) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC;


--   ============================================================
--   SECTION 17: STORE CITY STANDARDIZATION CHECK

SELECT
    city,
    COUNT(*) AS store_count
FROM stores
GROUP BY city
ORDER BY city;


--   ============================================================
--   SECTION 18: SUPPLIER COUNTRY STANDARDIZATION CHECK

SELECT
    country,
    COUNT(*) AS supplier_count
FROM suppliers
GROUP BY country
ORDER BY supplier_count DESC;


--   ============================================================
--   SECTION 19: FINAL DATA QUALITY SUMMARY

SELECT
    (SELECT COUNT(*) FROM categories) AS categories_rows,
    (SELECT COUNT(*) FROM customers) AS customers_rows,
    (SELECT COUNT(*) FROM stores) AS stores_rows,
    (SELECT COUNT(*) FROM suppliers) AS suppliers_rows,
    (SELECT COUNT(*) FROM promotions) AS promotions_rows,
    (SELECT COUNT(*) FROM products) AS products_rows,
    (SELECT COUNT(*) FROM employees) AS employees_rows,
    (SELECT COUNT(*) FROM orders) AS orders_rows,
    (SELECT COUNT(*) FROM order_items) AS order_items_rows,
    (SELECT COUNT(*) FROM payments) AS payments_rows,
    (SELECT COUNT(*) FROM shipments) AS shipments_rows,
    (SELECT COUNT(*) FROM returns) AS returns_rows;


--   ============================================================
--   SECTION 20: FINAL CRITICAL QUALITY CHECK

SELECT

    -- PRODUCTS
    (
        SELECT COUNT(*)
        FROM products
        WHERE price IS NULL
           OR price <= 0
    ) AS invalid_products,

    -- EMPLOYEES
    (
        SELECT COUNT(*)
        FROM employees
        WHERE salary IS NULL
           OR salary <= 0
    ) AS invalid_employees,

    -- ORDER ITEMS
    (
        SELECT COUNT(*)
        FROM order_items
        WHERE qty IS NULL
           OR qty <= 0
           OR price IS NULL
           OR price <= 0
    ) AS invalid_order_items,

    -- PAYMENTS
    (
        SELECT COUNT(*)
        FROM payments
        WHERE amount IS NULL
           OR amount < 0
    ) AS invalid_payments,

    -- RETURNS
    (
        SELECT COUNT(*)
        FROM returns
        WHERE refund IS NULL
           OR refund < 0
    ) AS invalid_returns,

    -- SHIPMENT STATUS
    (
        SELECT COUNT(*)
        FROM shipments
        WHERE status IS NULL
           OR status NOT IN ('SHIPPED', 'DELIVERED', 'LATE')
    ) AS invalid_shipment_status,

    -- ORDER BEFORE SIGNUP
    (
        SELECT COUNT(*)
        FROM orders o
        JOIN customers c
            ON o.customer_id = c.customer_id
        WHERE o.order_date < c.signup_date
    ) AS orders_before_signup;




/* ======================= END OF FILE ======================== */