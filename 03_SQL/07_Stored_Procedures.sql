
--   ===============================================================
--   PROJECT: MULTI-BRANCH RETAIL PERFORMANCE & REVENUE INTELLIGENCE
--   DATABASE: MySQL 8.0
--   FILE: 07_Stored_Procedures.sql
--   PURPOSE: Create reusable parameterized procedures for common 
-- 		business-analysis requests.
--   DATABASE: retail_dw
--   PROCEDURES:
--  	1. sp_store_performance
-- 		2. sp_customer_performance
-- 		3. sp_sales_summary_by_date
-- =================================================================


USE retail_dw;


--   ============================================================
--   PROCEDURE 1: STORE PERFORMANCE
--   ============================================================
--   PURPOSE: Returns performance KPIs for a selected store.
--   INPUT: p_store_id
--   SOURCE: vw_store_performance
--   GRAIN OF SOURCE VIEW: One row per store.

DROP PROCEDURE IF EXISTS sp_store_performance;

DELIMITER $$
CREATE PROCEDURE sp_store_performance(
    IN p_store_id INT
)
BEGIN
    SELECT
        store_id,
        city,
        total_orders,
        unique_customers,
        total_quantity,
        gross_sales,
        avg_order_value
    FROM vw_store_performance
    WHERE store_id = p_store_id;
END $$
DELIMITER ;


--   ============================================================
--   TEST PROCEDURE 1
--   ============================================================

CALL sp_store_performance(1);
CALL sp_store_performance(50);
CALL sp_store_performance(100);
CALL sp_store_performance(999999);


--   ============================================================
--   PROCEDURE 2: CUSTOMER PERFORMANCE
--   ============================================================
--   PURPOSE: Returns performance KPIs for a selected customer.
--   INPUT: p_customer_id
--   SOURCE: vw_customer_performance
--   GRAIN OF SOURCE VIEW: One row per customer.

DROP PROCEDURE IF EXISTS sp_customer_performance;

DELIMITER $$
CREATE PROCEDURE sp_customer_performance(
    IN p_customer_id INT
)
BEGIN
    SELECT
        customer_id,
        city,
        total_orders,
        total_quantity,
        gross_sales,
        avg_order_value,
        first_order_date,
        last_order_date
    FROM vw_customer_performance
    WHERE customer_id = p_customer_id;
END $$
DELIMITER ;

--   ============================================================
--   TEST PROCEDURE 2
--   ============================================================

CALL sp_customer_performance(1);
CALL sp_customer_performance(25000);
CALL sp_customer_performance(50000);
CALL sp_customer_performance(999999);


--   ========================================================================
--   PROCEDURE 3: SALES SUMMARY BY DATE RANGE
--   ========================================================================
--   PURPOSE: Returns overall sales KPIs for a selected date range.
--   INPUTS: p_start_date, p_end_date
--   SOURCE: vw_sales_detail
--   BUSINESS USE: Allows management to dynamically analyse sales performance
--   	for a selected reporting period.

DROP PROCEDURE IF EXISTS sp_sales_summary_by_date;

DELIMITER $$
CREATE PROCEDURE sp_sales_summary_by_date(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS unique_customers,
        COUNT(DISTINCT store_id) AS active_stores,
        SUM(qty) AS total_quantity,
        ROUND(SUM(gross_sales), 2) AS gross_sales,
        ROUND(
            SUM(gross_sales) / NULLIF(COUNT(DISTINCT order_id), 0),
            2
        ) AS avg_order_value
    FROM vw_sales_detail
    WHERE order_date BETWEEN p_start_date AND p_end_date;
END $$
DELIMITER ;


--   ============================================================
--   TEST PROCEDURE 3
--   ============================================================

-- TEST 1: Full year
CALL sp_sales_summary_by_date('2020-01-01', '2020-12-31');

-- TEST 2: Different full year
CALL sp_sales_summary_by_date('2023-01-01', '2023-12-31');

-- TEST 3: One month
CALL sp_sales_summary_by_date('2022-01-01', '2022-01-31');

-- TEST 4: Full available period
CALL sp_sales_summary_by_date('2020-01-01', '2024-01-01');

-- TEST 5: Period outside dataset
CALL sp_sales_summary_by_date('2030-01-01', '2030-12-31');

SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order
FROM vw_sales_detail;

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(qty) AS total_quantity,
    ROUND(SUM(gross_sales),2) AS gross_sales
FROM vw_sales_detail;



/* ======================= END OF FILE ======================== */