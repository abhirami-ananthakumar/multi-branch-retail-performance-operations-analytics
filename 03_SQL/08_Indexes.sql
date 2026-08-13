
--   ================================================================
--   PROJECT: MULTI-BRANCH RETAIL PERFORMANCE & REVENUE INTELLIGENCE
--   DATABASE: MySQL 8.0
--   FILE: 05_Business_Queries.sql
--   PURPOSE:
--       Audit and optimize indexes used by analytical queries.
-- 	 OBJECTIVES:
-- 		1. Review indexes already available in the database.
-- 		2. Avoid redundant or duplicate indexes.
-- 		3. Identify frequently filtered / joined columns.
-- 		4. Evaluate query execution plans using EXPLAIN.
-- 		5. Add only indexes that provide genuine analytical value.
--   ================================================================


USE retail_dw;


-- ============================================================
-- PART 1: EXISTING INDEX AUDIT
-- ============================================================

-- 1. ORDERS
SHOW INDEX FROM orders;

-- 2. ORDER ITEMS
SHOW INDEX FROM order_items;

-- 3. RETURNS
SHOW INDEX FROM returns;

-- 4. PAYMENTS
SHOW INDEX FROM payments;

-- 5. SHIPMENTS
SHOW INDEX FROM shipments;

-- 6. PRODUCTS
SHOW INDEX FROM products;

-- 7. EMPLOYEES
SHOW INDEX FROM employees;


--   ==================================================================================
--   INDEX 1: ORDER DATE
--   Purpose: Improve selective date-range filtering used in sales analysis.
--   EXPLAIN validation: Broad annual range may use a full table scan because a large
-- 		portion of the table is required.
--   Validation:
-- 		Before indexing:
--   		Access type     : ALL
--   		Rows examined   : ~299,440
--  		Index used      : None
-- 		After indexing (selective monthly range):
--   		Access type     : range
--   		Rows estimated  : ~6,369
--   		Index used      : idx_orders_order_date
--   		Extra           : Using index condition
--   Note: MySQL may still choose a full table scan for broad date ranges when scanning 
-- 		the table is estimated to be cheaper.
--   ==================================================================================


--   ============================================================
--   STEP 1: Query plan BEFORE index

EXPLAIN
SELECT
    order_id,
    customer_id,
    store_id,
    order_date,
    promotion_id
FROM orders
WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31';


--   ============================================================
--   STEP 2: Create order_date index

CREATE INDEX idx_orders_order_date
ON orders (order_date);


--   ============================================================
--   STEP 3: Verify index

SHOW INDEX FROM orders;


--   ============================================================
--   STEP 4: Query plan AFTER index

EXPLAIN
SELECT
    order_id,
    customer_id,
    store_id,
    order_date,
    promotion_id
FROM orders
WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31';


--   ============================================================
--   STEP 5: More selective date-range test
--   Demonstrates index usage more clearly

EXPLAIN
SELECT
    order_id,
    customer_id,
    store_id,
    order_date,
    promotion_id
FROM orders
WHERE order_date BETWEEN '2023-01-01' AND '2023-01-31';

/*
Observation:

For a broad one-year range, MySQL may still choose a full table
scan because a large percentage of the table is required.

For the more selective one-month range, MySQL can use
idx_orders_order_date with a RANGE scan, reducing the number
of rows examined.

This demonstrates that index usage depends on query selectivity.
*/


-- ============================================================
--   INDEX TEST 2: COMPOSITE STORE + DATE INDEX
--   Purpose: Optimize queries filtering simultaneously by store and date.


--   ============================================================
--   STEP 1: Query plan BEFORE composite index

EXPLAIN
SELECT
    order_id,
    customer_id,
    store_id,
    order_date,
    promotion_id
FROM orders
WHERE store_id = 50
  AND order_date BETWEEN '2023-01-01' AND '2023-12-31';


--   ============================================================
--   STEP 2: Create composite index

CREATE INDEX idx_orders_store_date
ON orders (store_id, order_date);


--   ============================================================
--   STEP 3: Verify index

SHOW INDEX FROM orders;


--   ============================================================
--   STEP 4: Query plan AFTER composite index

EXPLAIN
SELECT
    order_id,
    customer_id,
    store_id,
    order_date,
    promotion_id
FROM orders
WHERE store_id = 50
  AND order_date BETWEEN '2023-01-01' AND '2023-12-31';


/*
Expected optimization:

Before composite index:
- MySQL can use the existing store_id foreign-key index.
- order_date is then applied as an additional filter.

After composite index:
- idx_orders_store_date becomes available.
- store_id and order_date can be evaluated together.
- This can reduce rows examined for selective store/date queries.

The composite index is particularly relevant to this project
because branch performance analysis frequently combines
store-level and time-period filtering.
*/



--   ====================================================================
--   TEST 2: COMPOSITE INDEX OPTIMIZATION
--   Purpose: Optimize queries that filter orders by both store and date.
--   Expected optimization:
--   	BEFORE:
--   	- MySQL may use the existing store_id index.
--   	- Date filtering is applied separately.
--   	AFTER:
--   	- idx_orders_store_date becomes available.
--   	- MySQL can use store_id + order_date together.
-- 		- This can reduce rows examined for selective store/date queries.
--   ====================================================================






/* ======================= END OF FILE ======================== */