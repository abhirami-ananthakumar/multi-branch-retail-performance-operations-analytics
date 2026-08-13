
--   ================================================================
--   PROJECT: MULTI-BRANCH RETAIL PERFORMANCE & REVENUE INTELLIGENCE
--   DATABASE: MySQL 8.0
--   FILE: 05_Business_Queries.sql
--   PURPOSE:
--       Answer decision-oriented retail business questions using
--   	 the cleaned and explored 12-table retail database.
--   ANALYTICAL PRINCIPLES:
--   ------------------------------------------------------------
--   1. Gross sales = order_items.qty * order_items.price
--   2. Gross sales must NOT be interpreted as profit because
--      the dataset contains no explicit product cost / COGS.
--   3. Customer signup_date is excluded from tenure/acquisition
--      analysis because 120,020 orders occur before signup_date.
--   4. Returned items are counted using DISTINCT order_item_id
--      because multiple return records may reference one item.
--   5. Promotion comparisons represent association, not causation.
--   6. Return timing cannot be determined because the returns
--      table contains no return_date.
--   ================================================================


USE retail_dw;


--   ============================================================
--   PART 1: EXECUTIVE REVENUE PERFORMANCE
--   ============================================================


--   ============================================================
--   BUSINESS QUESTION 1
--   What is the overall commercial scale of the retail business?
--   	Provides a high-level executive snapshot:
--   	customers, orders, units and gross sales.

SELECT
    COUNT(DISTINCT o.customer_id) AS active_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS total_units_sold,
    ROUND(
        SUM(oi.qty * oi.price),
        2
    ) AS gross_sales,
    ROUND(
        SUM(oi.qty * oi.price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS avg_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id;


--   ============================================================
--   BUSINESS QUESTION 2
--   How has annual revenue performance changed over time?

WITH yearly_sales AS
(
    SELECT
        YEAR(o.order_date) AS sales_year,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.qty) AS units_sold,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY YEAR(o.order_date)
),
yearly_comparison AS
(
    SELECT
        sales_year,
        total_orders,
        units_sold,
        gross_sales,
        LAG(gross_sales) OVER (
            ORDER BY sales_year
        ) AS previous_year_sales
    FROM yearly_sales
)
SELECT
    sales_year,
    total_orders,
    units_sold,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(
        gross_sales / total_orders,
        2
    ) AS avg_order_value,
    ROUND(previous_year_sales, 2)
        AS previous_year_sales,
    ROUND(
        (
            gross_sales - previous_year_sales
        )
        / NULLIF(previous_year_sales, 0)
        * 100,
        2
    ) AS yoy_sales_growth_pct
FROM yearly_comparison
ORDER BY sales_year;


--   ============================================================
--   BUSINESS QUESTION 3
--   Which months generated the strongest and weakest sales?
-- 		RANK() identifies relative monthly performance.
-- 		Each YYYY-MM period is treated separately.

WITH monthly_sales AS
(
    SELECT
        DATE_FORMAT(
            o.order_date,
            '%Y-%m'
        ) AS sales_month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        DATE_FORMAT(
            o.order_date,
            '%Y-%m'
        )
),
ranked_months AS
(
    SELECT
        sales_month,
        total_orders,
        gross_sales,

        RANK() OVER (
            ORDER BY gross_sales DESC
        ) AS sales_rank
    FROM monthly_sales
)
SELECT
    sales_month,
    total_orders,
    ROUND(gross_sales, 2) AS gross_sales,
    sales_rank
FROM ranked_months
ORDER BY sales_rank;


--   =====================================================================
--   BUSINESS QUESTION 4
--   Is revenue growth driven more by order volume or average order value?
--  	This decomposes annual sales performance into:
-- 		1. Number of orders
-- 		2. Average value generated per order
-- 		This helps management understand whether changes in sales
-- 		are coming from transaction volume or basket value.

WITH yearly_metrics AS
(
    SELECT
        YEAR(o.order_date) AS sales_year,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY YEAR(o.order_date)
),
metrics AS
(
    SELECT
        sales_year,
        total_orders,
        gross_sales,
        gross_sales /
        NULLIF(total_orders, 0) AS avg_order_value
    FROM yearly_metrics
),
comparison AS
(
    SELECT *,
        LAG(total_orders) OVER (
            ORDER BY sales_year
        ) AS previous_orders,
        LAG(avg_order_value) OVER (
            ORDER BY sales_year
        ) AS previous_aov
    FROM metrics
)
SELECT
    sales_year,
    total_orders,
    ROUND(
        avg_order_value,
        2
    ) AS avg_order_value,
    ROUND(
        (
            total_orders - previous_orders
        )
        / NULLIF(previous_orders, 0)
        * 100,
        2
    ) AS order_growth_pct,
    ROUND(
        (
            avg_order_value - previous_aov
        )
        / NULLIF(previous_aov, 0)
        * 100,
        2
    ) AS aov_growth_pct
FROM comparison
ORDER BY sales_year;


--   ============================================================
--   BUSINESS QUESTION 5
--   How concentrated is revenue across months?
-- 		Calculates each month's contribution to total gross sales.

WITH monthly_sales AS
(
    SELECT
        DATE_FORMAT(
            o.order_date,
            '%Y-%m'
        ) AS sales_month,
        SUM(
            oi.qty * oi.price
        ) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        DATE_FORMAT(
            o.order_date,
            '%Y-%m'
        )
)
SELECT
    sales_month,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (),
        2
    ) AS total_sales_contribution_pct,
    ROUND(
        SUM(gross_sales) OVER (
            ORDER BY gross_sales DESC
        )
        * 100.0 /
        SUM(gross_sales) OVER (),
        2
    ) AS cumulative_sales_contribution_pct
FROM monthly_sales
ORDER BY gross_sales DESC;


--   =================================================================
--   BUSINESS QUESTION 6
--   Which days of the week generate the greatest commercial activity?

SELECT
    WEEKDAY(o.order_date) AS weekday_number,
    DAYNAME(o.order_date) AS day_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS units_sold,
    ROUND(
        SUM(oi.qty * oi.price),
        2
    ) AS gross_sales,
    ROUND(
        SUM(oi.qty * oi.price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS avg_order_value,
    ROUND(
        SUM(oi.qty * oi.price)
        * 100.0 /
        SUM(
            SUM(oi.qty * oi.price)
        ) OVER (),
        2
    ) AS sales_contribution_pct
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    WEEKDAY(o.order_date),
    DAYNAME(o.order_date)
ORDER BY gross_sales DESC;


--   =================================================================
--   BUSINESS QUESTION 7
--   What is the company's net revenue exposure after refunds?
-- 		IMPORTANT:
-- 		This is NOT profit.
-- 		Revenue after recorded refunds: Gross Sales - Recorded Refunds
--  	Refunds are first aggregated separately to prevent
--  	multiplication when joined to transactional data.

WITH sales_summary AS
(
    SELECT
        SUM(qty * price) AS gross_sales
    FROM order_items
),
refund_summary AS
(
    SELECT
        SUM(refund) AS total_refunds
    FROM returns
)
SELECT
    ROUND(
        ss.gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        rs.total_refunds,
        2
    ) AS total_refunds,
    ROUND(
        ss.gross_sales - rs.total_refunds,
        2
    ) AS revenue_after_refunds,
    ROUND(
        rs.total_refunds /
        NULLIF(ss.gross_sales, 0)
        * 100,
        2
    ) AS refund_to_sales_pct
FROM sales_summary ss
CROSS JOIN refund_summary rs;


--   ============================================================
--   BUSINESS QUESTION 8
--   What percentage of transactions are associated with
--   promotions, and how much sales value do they represent?
-- 		This measures promotion exposure.
-- 		It does NOT claim promotions caused the observed sales.

WITH promotion_performance AS
(
    SELECT
        CASE
            WHEN o.promotion_id IS NULL
                THEN 'No Promotion'
            ELSE 'Promotion'
        END AS promotion_status,
        COUNT(DISTINCT o.order_id)
            AS total_orders,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        CASE
            WHEN o.promotion_id IS NULL
                THEN 'No Promotion'
            ELSE 'Promotion'
        END
)
SELECT
    promotion_status,
    total_orders,
    ROUND(
        total_orders * 100.0 /
        SUM(total_orders) OVER (),
        2
    ) AS order_share_pct,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (),
        2
    ) AS sales_share_pct,
    ROUND(
        gross_sales /
        NULLIF(total_orders, 0),
        2
    ) AS avg_order_value
FROM promotion_performance
ORDER BY gross_sales DESC;


--   ============================================================
--   PART 2: BRANCH & STORE PERFORMANCE
--   ============================================================


--   ============================================================
--   BUSINESS QUESTION 9
--   Which branches generate the highest gross sales?

WITH store_performance AS
(
    SELECT
        s.store_id,
        s.city,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.qty) AS units_sold,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM stores s
    LEFT JOIN orders o
        ON s.store_id = o.store_id
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        s.store_id,
        s.city
)
SELECT
    store_id,
    city,
    total_orders,
    units_sold,
    ROUND(gross_sales, 2) AS gross_sales,
    RANK() OVER (
        ORDER BY gross_sales DESC
    ) AS sales_rank
FROM store_performance
ORDER BY sales_rank;


--   ============================================================
--   BUSINESS QUESTION 10
--   How much does each branch contribute to company sales?

WITH store_sales AS
(
    SELECT
        s.store_id,
        s.city,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM stores s
    JOIN orders o
        ON s.store_id = o.store_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        s.store_id,
        s.city
)
SELECT
    store_id,
    city,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (),
        2
    ) AS sales_contribution_pct,
    RANK() OVER (
        ORDER BY gross_sales DESC
    ) AS sales_rank
FROM store_sales
ORDER BY sales_rank;


--   =============================================================================
--   BUSINESS QUESTION 11
--   Which branches perform above or below the company-average branch sales level?

WITH store_sales AS
(
    SELECT
        s.store_id,
        s.city,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM stores s
    JOIN orders o
        ON s.store_id = o.store_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        s.store_id,
        s.city
),
benchmarked AS
(
    SELECT
        *,
        AVG(gross_sales) OVER ()
            AS company_avg_store_sales
    FROM store_sales
)
SELECT
    store_id,
    city,
    ROUND(gross_sales, 2)
        AS gross_sales,
    ROUND(company_avg_store_sales, 2)
        AS company_avg_store_sales,
    ROUND(
        gross_sales - company_avg_store_sales,
        2
    ) AS difference_from_average,
    ROUND(
        (
            gross_sales - company_avg_store_sales
        )
        / NULLIF(company_avg_store_sales, 0)
        * 100,
        2
    ) AS difference_from_average_pct,
    CASE
        WHEN gross_sales >= company_avg_store_sales
            THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_vs_average
FROM benchmarked
ORDER BY gross_sales DESC;


--   ============================================================
--   BUSINESS QUESTION 12
--   Which branches have the highest average order value?
-- 		Calculate order value FIRST so that the average is
-- 		calculated at order grain rather than order-item grain.

WITH order_values AS
(
    SELECT
        o.order_id,
        o.store_id,
        SUM(oi.qty * oi.price)
            AS order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.store_id
),
store_aov AS
(
    SELECT
        store_id,
        COUNT(*) AS total_orders,
        AVG(order_value) AS avg_order_value
    FROM order_values
    GROUP BY store_id
)
SELECT
    s.store_id,
    s.city,
    sa.total_orders,
    ROUND(
        sa.avg_order_value,
        2
    ) AS avg_order_value,

    RANK() OVER (
        ORDER BY sa.avg_order_value DESC
    ) AS aov_rank
FROM stores s
JOIN store_aov sa
    ON s.store_id = sa.store_id
ORDER BY aov_rank;


--   ============================================================
--   BUSINESS QUESTION 13
--   Which branches reach the largest number of customers?

WITH store_customers AS
(
    SELECT
        store_id,
        COUNT(DISTINCT customer_id)
            AS unique_customers,
        COUNT(DISTINCT order_id)
            AS total_orders
    FROM orders
    GROUP BY store_id
)
SELECT
    s.store_id,
    s.city,
    sc.unique_customers,
    sc.total_orders,
    ROUND(
        sc.total_orders * 1.0 /
        NULLIF(sc.unique_customers, 0),
        2
    ) AS orders_per_customer,
    RANK() OVER (
        ORDER BY sc.unique_customers DESC
    ) AS customer_reach_rank
FROM stores s
JOIN store_customers sc
    ON s.store_id = sc.store_id
ORDER BY customer_reach_rank;


--   ============================================================
--   BUSINESS QUESTION 14
--   Which branches generate the most sales per active customer?

WITH store_metrics AS
(
    SELECT
        o.store_id,
        COUNT(DISTINCT o.customer_id)
            AS unique_customers,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.store_id
)
SELECT
    s.store_id,
    s.city,
    sm.unique_customers,
    ROUND(
        sm.gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        sm.gross_sales /
        NULLIF(sm.unique_customers, 0),
        2
    ) AS sales_per_customer,
    RANK() OVER (
        ORDER BY
            sm.gross_sales /
            NULLIF(sm.unique_customers, 0)
        DESC
    ) AS sales_per_customer_rank
FROM stores s
JOIN store_metrics sm
    ON s.store_id = sm.store_id
ORDER BY sales_per_customer_rank;


--   ============================================================
--   BUSINESS QUESTION 15
--   Which branches generate the most sales per employee?
-- 		Sales and employee counts are aggregated independently
-- 		before joining to prevent row multiplication.

WITH store_sales AS
(
    SELECT
        o.store_id,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.store_id
),
store_workforce AS
(
    SELECT
        store_id,
        COUNT(*) AS employee_count
    FROM employees
    GROUP BY store_id
)
SELECT
    s.store_id,
    s.city,
    sw.employee_count,
    ROUND(
        ss.gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        ss.gross_sales /
        NULLIF(sw.employee_count, 0),
        2
    ) AS sales_per_employee,
    RANK() OVER (
        ORDER BY
            ss.gross_sales /
            NULLIF(sw.employee_count, 0)
        DESC
    ) AS productivity_rank
FROM stores s
JOIN store_sales ss
    ON s.store_id = ss.store_id
JOIN store_workforce sw
    ON s.store_id = sw.store_id
ORDER BY productivity_rank;


--   ============================================================
--   BUSINESS QUESTION 16
--   How does branch sales compare with salary expenditure?
-- 		IMPORTANT: This is NOT profit or labor profitability.
-- 		Salary data has no confirmed payroll period in the
-- 		analytical model, so this is treated only as an
-- 		operational exposure/ratio.

WITH store_sales AS
(
    SELECT
        o.store_id,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.store_id
),
store_salary AS
(
    SELECT
        store_id,
        COUNT(*) AS employee_count,
        SUM(salary) AS total_salary
    FROM employees
    GROUP BY store_id
)
SELECT
    s.store_id,
    s.city,
    sal.employee_count,
    ROUND(
        sal.total_salary,
        2
    ) AS total_salary,
    ROUND(
        ss.gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        ss.gross_sales /
        NULLIF(sal.total_salary, 0),
        2
    ) AS sales_to_salary_ratio
FROM stores s
JOIN store_sales ss
    ON s.store_id = ss.store_id
JOIN store_salary sal
    ON s.store_id = sal.store_id
ORDER BY sales_to_salary_ratio DESC;


--   =======================================================================
--   BUSINESS QUESTION 17
--   Which branches experience the highest return rates and refund exposure?
-- 		Returned items use DISTINCT order_item_id.

WITH store_returns AS
(
    SELECT
        o.store_id,
        COUNT(DISTINCT oi.order_item_id)
            AS total_order_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_order_items,
        COALESCE(
            SUM(r.refund),
            0
        ) AS total_refunds
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY o.store_id
)
SELECT
    s.store_id,
    s.city,
    sr.total_order_items,
    sr.returned_order_items,
    ROUND(
        sr.returned_order_items * 100.0 /
        NULLIF(sr.total_order_items, 0),
        2
    ) AS return_rate_pct,
    ROUND(
        sr.total_refunds,
        2
    ) AS total_refunds,
    RANK() OVER (
        ORDER BY
            sr.returned_order_items * 1.0 /
            NULLIF(sr.total_order_items, 0)
        DESC
    ) AS return_rate_rank
FROM stores s
JOIN store_returns sr
    ON s.store_id = sr.store_id
ORDER BY return_rate_rank;


--   ===============================================================================
--   BUSINESS QUESTION 18
--   Which branches have the greatest refund exposure relative to their gross sales?
-- 		Refund-to-sales ratio is NOT a profit-margin measure.

WITH store_sales AS
(
    SELECT
        o.store_id,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.store_id
),
store_refunds AS
(
    SELECT
        o.store_id,
        SUM(r.refund)
            AS total_refunds
    FROM returns r
    JOIN order_items oi
        ON r.order_item_id = oi.order_item_id
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY o.store_id
)
SELECT
    s.store_id,
    s.city,
    ROUND(
        ss.gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        COALESCE(sr.total_refunds, 0),
        2
    ) AS total_refunds,
    ROUND(
        COALESCE(sr.total_refunds, 0)
        / NULLIF(ss.gross_sales, 0)
        * 100,
        2
    ) AS refund_to_sales_pct
FROM stores s
JOIN store_sales ss
    ON s.store_id = ss.store_id
LEFT JOIN store_refunds sr
    ON s.store_id = sr.store_id
ORDER BY refund_to_sales_pct DESC;


--   =============================================================
--   BUSINESS QUESTION 19
--   Which branches have the highest proportion of late shipments?

WITH store_shipments AS
(
    SELECT
        o.store_id,
        COUNT(*) AS total_shipments,
        SUM(
            CASE
                WHEN sh.status = 'LATE'
                    THEN 1
                ELSE 0
            END
        ) AS late_shipments
    FROM orders o
    JOIN shipments sh
        ON o.order_id = sh.order_id
    GROUP BY o.store_id
)
SELECT
    s.store_id,
    s.city,
    ss.total_shipments,
    ss.late_shipments,
    ROUND(
        ss.late_shipments * 100.0 /
        NULLIF(ss.total_shipments, 0),
        2
    ) AS late_shipment_rate_pct,
    RANK() OVER (
        ORDER BY
            ss.late_shipments * 1.0 /
            NULLIF(ss.total_shipments, 0)
        DESC
    ) AS late_shipment_rank
FROM stores s
JOIN store_shipments ss
    ON s.store_id = ss.store_id
ORDER BY late_shipment_rank;


--   =========================================================================
--   BUSINESS QUESTION 20
--   Which branches combine strong sales with operational risk?
-- 		Creates an executive branch diagnostic using:
-- 		Revenue performance,
-- 		Return rate,
-- 		Late-shipment rate.
-- 		Each branch is benchmarked against the company average for each metric.

WITH store_sales AS
(
    SELECT
        o.store_id,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.store_id
),
store_returns AS
(
    SELECT
        o.store_id,
        COUNT(DISTINCT oi.order_item_id)
            AS total_order_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_items
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY o.store_id
),
store_shipments AS
(
    SELECT
        o.store_id,
        COUNT(*) AS total_shipments,
        SUM(
            CASE
                WHEN sh.status = 'LATE'
                    THEN 1
                ELSE 0
            END
        ) AS late_shipments
    FROM orders o
    JOIN shipments sh
        ON o.order_id = sh.order_id
    GROUP BY o.store_id
),
store_metrics AS
(
    SELECT
        s.store_id,
        s.city,
        ss.gross_sales,
        sr.returned_items * 100.0 /
        NULLIF(sr.total_order_items, 0)
            AS return_rate,
        sh.late_shipments * 100.0 /
        NULLIF(sh.total_shipments, 0)
            AS late_shipment_rate
    FROM stores s
    JOIN store_sales ss
        ON s.store_id = ss.store_id
    JOIN store_returns sr
        ON s.store_id = sr.store_id
    JOIN store_shipments sh
        ON s.store_id = sh.store_id
),
benchmarked AS
(
    SELECT
        *,
        AVG(gross_sales) OVER ()
            AS avg_store_sales,
        AVG(return_rate) OVER ()
            AS avg_return_rate,
        AVG(late_shipment_rate) OVER ()
            AS avg_late_shipment_rate
    FROM store_metrics
)
SELECT
    store_id,
    city,
    ROUND(gross_sales, 2)
        AS gross_sales,
    ROUND(return_rate, 2)
        AS return_rate_pct,
    ROUND(late_shipment_rate, 2)
        AS late_shipment_rate_pct,
    CASE
        WHEN gross_sales >= avg_store_sales
             AND return_rate <= avg_return_rate
             AND late_shipment_rate <= avg_late_shipment_rate
            THEN 'Strong & Operationally Healthy'
        WHEN gross_sales >= avg_store_sales
             AND (
                 return_rate > avg_return_rate
                 OR late_shipment_rate > avg_late_shipment_rate
             )
            THEN 'High Sales - Operational Risk'
        WHEN gross_sales < avg_store_sales
             AND return_rate <= avg_return_rate
             AND late_shipment_rate <= avg_late_shipment_rate
            THEN 'Lower Sales - Operationally Healthy'
        ELSE 'Performance Attention Required'
    END AS branch_performance_segment
FROM benchmarked
ORDER BY gross_sales DESC;


--   ============================================================
--   BUSINESS QUESTION 21
--   How many branches fall into each performance segment?

WITH store_sales AS
(
    SELECT
        o.store_id,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.store_id
),
store_returns AS
(
    SELECT
        o.store_id,
        COUNT(DISTINCT oi.order_item_id)
            AS total_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_items
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY o.store_id
),
store_shipments AS
(
    SELECT
        o.store_id,
        COUNT(*) AS total_shipments,
        SUM(
            CASE
                WHEN sh.status = 'LATE' THEN 1
                ELSE 0
            END
        ) AS late_shipments
    FROM orders o
    JOIN shipments sh
        ON o.order_id = sh.order_id
    GROUP BY o.store_id
),
metrics AS
(
    SELECT
        ss.store_id,
        ss.gross_sales,
        sr.returned_items * 100.0 /
        NULLIF(sr.total_items, 0)
            AS return_rate,
        sh.late_shipments * 100.0 /
        NULLIF(sh.total_shipments, 0)
            AS late_rate
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.store_id = sr.store_id
    JOIN store_shipments sh
        ON ss.store_id = sh.store_id
),
benchmarked AS
(
    SELECT
        *,
        AVG(gross_sales) OVER ()
            AS avg_sales,
        AVG(return_rate) OVER ()
            AS avg_return_rate,
        AVG(late_rate) OVER ()
            AS avg_late_rate
    FROM metrics
),
segmented AS
(
    SELECT
        *,
        CASE
            WHEN gross_sales >= avg_sales
                 AND return_rate <= avg_return_rate
                 AND late_rate <= avg_late_rate
                THEN 'Strong & Operationally Healthy'
            WHEN gross_sales >= avg_sales
                 AND (
                     return_rate > avg_return_rate
                     OR late_rate > avg_late_rate
                 )
                THEN 'High Sales - Operational Risk'
            WHEN gross_sales < avg_sales
                 AND return_rate <= avg_return_rate
                 AND late_rate <= avg_late_rate
                THEN 'Lower Sales - Operationally Healthy'
            ELSE 'Performance Attention Required'
        END AS branch_segment
    FROM benchmarked
)
SELECT
    branch_segment,
    COUNT(*) AS total_branches,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS branch_percentage
FROM segmented
GROUP BY branch_segment
ORDER BY total_branches DESC;


--   ============================================================
--   PART 3: PRODUCT & CATEGORY PERFORMANCE
--   ============================================================


--   ============================================================
--   BUSINESS QUESTION 22
--   Which products generate the highest gross sales?

WITH product_sales AS
(
    SELECT
        p.product_id,
        c.category_name,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(oi.qty) AS units_sold,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM products p
    JOIN categories c
        ON p.category_id = c.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.product_id,
        c.category_name
)
SELECT
    product_id,
    category_name,
    total_orders,
    units_sold,
    ROUND(gross_sales, 2) AS gross_sales,
    RANK() OVER (
        ORDER BY gross_sales DESC
    ) AS revenue_rank
FROM product_sales
ORDER BY revenue_rank;


--   ============================================================
--   BUSINESS QUESTION 23
--   How much does each product contribute to company sales?

WITH product_sales AS
(
    SELECT
        p.product_id,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY p.product_id
)
SELECT
    product_id,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (),
        4
    ) AS company_sales_contribution_pct,
    RANK() OVER (
        ORDER BY gross_sales DESC
    ) AS revenue_rank
FROM product_sales
ORDER BY revenue_rank;


--   ============================================================
--   BUSINESS QUESTION 24
--   How concentrated is company revenue among products?
-- 		Calculates cumulative product contribution.
-- 		This helps determine whether a relatively small number
-- 		of products generate a large share of sales.

WITH product_sales AS
(
    SELECT
        product_id,
        SUM(qty * price) AS gross_sales
    FROM order_items
    GROUP BY product_id
),
ranked_products AS
(
    SELECT
        product_id,
        gross_sales,
        RANK() OVER (
            ORDER BY gross_sales DESC
        ) AS revenue_rank,
        SUM(gross_sales) OVER (
            ORDER BY gross_sales DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_sales,
        SUM(gross_sales) OVER ()
            AS company_sales
    FROM product_sales
)
SELECT
    product_id,
    revenue_rank,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales /
        NULLIF(company_sales, 0)
        * 100,
        4
    ) AS sales_contribution_pct,
    ROUND(
        cumulative_sales /
        NULLIF(company_sales, 0)
        * 100,
        2
    ) AS cumulative_sales_pct
FROM ranked_products
ORDER BY
    gross_sales DESC,
    product_id;


--   ====================================================================================
--   BUSINESS QUESTION 25
--   How many products are required to generate approximately 80% of company gross sales?

WITH product_sales AS
(
    SELECT
        product_id,
        SUM(qty * price) AS gross_sales
    FROM order_items
    GROUP BY product_id
),
cumulative_analysis AS
(
    SELECT
        product_id,
        gross_sales,
        SUM(gross_sales) OVER (
            ORDER BY gross_sales DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_sales,
        SUM(gross_sales) OVER ()
            AS total_sales
    FROM product_sales
),
contribution AS
(
    SELECT
        *,
        cumulative_sales /
        NULLIF(total_sales, 0)
        * 100 AS cumulative_pct
    FROM cumulative_analysis
),
threshold AS
(
    SELECT
        MIN(cumulative_sales) AS threshold_sales
    FROM contribution
    WHERE cumulative_pct >= 80
)
SELECT
    COUNT(*) AS products_required_for_80_pct_sales,
    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM product_sales
        ),
        2
    ) AS pct_of_selling_products,
    ROUND(
        MAX(c.cumulative_pct),
        2
    ) AS cumulative_sales_pct
FROM contribution c
CROSS JOIN threshold t
WHERE c.cumulative_sales <= t.threshold_sales;


--   ============================================================
--   BUSINESS QUESTION 26
--   Which categories generate the highest gross sales?

WITH category_performance AS
(
    SELECT
        c.category_id,
        c.category_name,
        COUNT(DISTINCT p.product_id)
            AS products_sold,
        COUNT(DISTINCT oi.order_id)
            AS total_orders,
        SUM(oi.qty)
            AS units_sold,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        c.category_id,
        c.category_name
)
SELECT
    category_id,
    category_name,
    products_sold,
    total_orders,
    units_sold,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (),
        2
    ) AS sales_contribution_pct,
    RANK() OVER (
        ORDER BY gross_sales DESC
    ) AS category_revenue_rank
FROM category_performance
ORDER BY category_revenue_rank;


--   ========================================================================================
--   BUSINESS QUESTION 27
--   Which products outperform or underperform the average product within their own category?
-- 		A product is benchmarked against products in the SAME category rather than 
-- 		against the entire catalog.

WITH product_sales AS
(
    SELECT
        p.product_id,
        p.category_id,
        c.category_name,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM products p
    JOIN categories c
        ON p.category_id = c.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.product_id,
        p.category_id,
        c.category_name
),
benchmarked AS
(
    SELECT
        *,
        AVG(gross_sales) OVER (
            PARTITION BY category_id
        ) AS category_avg_product_sales
    FROM product_sales
)
SELECT
    product_id,
    category_name,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        category_avg_product_sales,
        2
    ) AS category_avg_product_sales,
    ROUND(
        (
            gross_sales -
            category_avg_product_sales
        )
        / NULLIF(
            category_avg_product_sales,
            0
        )
        * 100,
        2
    ) AS difference_from_category_avg_pct,
    CASE
        WHEN gross_sales >= category_avg_product_sales
            THEN 'Above Category Average'
        ELSE 'Below Category Average'
    END AS category_performance
FROM benchmarked
ORDER BY gross_sales DESC;


--   ============================================================
--   BUSINESS QUESTION 28
--   Which products rank highest within each category?

WITH product_sales AS
(
    SELECT
        p.product_id,
        p.category_id,
        c.category_name,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM products p
    JOIN categories c
        ON p.category_id = c.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.product_id,
        p.category_id,
        c.category_name
),
ranked AS
(
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY category_id
            ORDER BY gross_sales DESC
        ) AS category_rank
    FROM product_sales
)
SELECT
    product_id,
    category_name,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    category_rank
FROM ranked
WHERE category_rank <= 5
ORDER BY
    category_name,
    category_rank,
    product_id;


--   ============================================================
--   BUSINESS QUESTION 29
--   Which products combine high unit demand with high revenue?
-- 		Products are benchmarked against company-wide average
-- 		units and average product gross sales.

WITH product_metrics AS
(
    SELECT
        product_id,
        SUM(qty) AS units_sold,
        SUM(qty * price) AS gross_sales
    FROM order_items
    GROUP BY product_id
),
benchmarked AS
(
    SELECT
        *,
        AVG(units_sold) OVER ()
            AS avg_product_units,
        AVG(gross_sales) OVER ()
            AS avg_product_sales
    FROM product_metrics
)
SELECT
    product_id,
    units_sold,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    CASE
        WHEN units_sold >= avg_product_units
             AND gross_sales >= avg_product_sales
            THEN 'High Demand - High Revenue'
        WHEN units_sold >= avg_product_units
             AND gross_sales < avg_product_sales
            THEN 'High Demand - Lower Revenue'
        WHEN units_sold < avg_product_units
             AND gross_sales >= avg_product_sales
            THEN 'Lower Demand - High Revenue'
        ELSE 'Lower Demand - Lower Revenue'
    END AS product_position
FROM benchmarked
ORDER BY gross_sales DESC;


--   ============================================================
--   BUSINESS QUESTION 30
--   How many products fall into each demand/revenue segment?

WITH product_metrics AS
(
    SELECT
        product_id,
        SUM(qty) AS units_sold,
        SUM(qty * price) AS gross_sales
    FROM order_items
    GROUP BY product_id
),
benchmarked AS
(
    SELECT
        *,
        AVG(units_sold) OVER ()
            AS avg_units,
        AVG(gross_sales) OVER ()
            AS avg_sales
    FROM product_metrics
),
segmented AS
(
    SELECT
        *,
        CASE
            WHEN units_sold >= avg_units
                 AND gross_sales >= avg_sales
                THEN 'High Demand - High Revenue'
            WHEN units_sold >= avg_units
                 AND gross_sales < avg_sales
                THEN 'High Demand - Lower Revenue'
            WHEN units_sold < avg_units
                 AND gross_sales >= avg_sales
                THEN 'Lower Demand - High Revenue'
            ELSE 'Lower Demand - Lower Revenue'
        END AS product_segment
    FROM benchmarked
)
SELECT
    product_segment,
    COUNT(*) AS total_products,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS product_percentage
FROM segmented
GROUP BY product_segment
ORDER BY total_products DESC;


--   ============================================================
--   BUSINESS QUESTION 31
--   Which products have the highest return rates?
-- 		DISTINCT returned order_item_id is used because multiple
-- 		return records can reference one order item.

WITH product_returns AS
(
    SELECT
        p.product_id,
        c.category_name,
        COUNT(DISTINCT oi.order_item_id)
            AS total_order_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_order_items
    FROM products p
    JOIN categories c
        ON p.category_id = c.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY
        p.product_id,
        c.category_name
)
SELECT
    product_id,
    category_name,
    total_order_items,
    returned_order_items,
    ROUND(
        returned_order_items * 100.0 /
        NULLIF(total_order_items, 0),
        2
    ) AS return_rate_pct,
    RANK() OVER (
        ORDER BY
            returned_order_items * 1.0 /
            NULLIF(total_order_items, 0)
        DESC
    ) AS return_rate_rank
FROM product_returns
ORDER BY return_rate_rank;


--   ============================================================
--   BUSINESS QUESTION 32
--   Which products create the greatest refund exposure?

WITH product_refunds AS
(
    SELECT
        p.product_id,
        c.category_name,
        SUM(oi.qty * oi.price)
            AS gross_sales,
        COALESCE(
            SUM(r.refund),
            0
        ) AS total_refunds
    FROM products p
    JOIN categories c
        ON p.category_id = c.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY
        p.product_id,
        c.category_name
)
SELECT
    product_id,
    category_name,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        total_refunds,
        2
    ) AS total_refunds,
    ROUND(
        total_refunds /
        NULLIF(gross_sales, 0)
        * 100,
        2
    ) AS refund_to_sales_pct,
    RANK() OVER (
        ORDER BY
            total_refunds /
            NULLIF(gross_sales, 0)
        DESC
    ) AS refund_exposure_rank
FROM product_refunds
ORDER BY refund_exposure_rank;


--   ============================================================
--   BUSINESS QUESTION 33
--   Which categories have the greatest return/refund exposure?

WITH category_risk AS
(
    SELECT
        c.category_id,
        c.category_name,
        COUNT(DISTINCT oi.order_item_id)
            AS total_order_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_items,
        SUM(oi.qty * oi.price)
            AS gross_sales,
        COALESCE(
            SUM(r.refund),
            0
        ) AS total_refunds
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY
        c.category_id,
        c.category_name
)
SELECT
    category_id,
    category_name,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        returned_items * 100.0 /
        NULLIF(total_order_items, 0),
        2
    ) AS return_rate_pct,
    ROUND(
        total_refunds,
        2
    ) AS total_refunds,
    ROUND(
        total_refunds /
        NULLIF(gross_sales, 0)
        * 100,
        2
    ) AS refund_to_sales_pct
FROM category_risk
ORDER BY refund_to_sales_pct DESC;


--   ==============================================================
--   BUSINESS QUESTION 34
--   Which products combine strong sales with elevated return risk?
-- 		Products are benchmarked against:
-- 		1. Average product sales
-- 		2. Average product return rate
-- 		This creates a management-oriented product diagnostic.

WITH product_metrics AS
(
    SELECT
        p.product_id,
        c.category_name,
        SUM(oi.qty * oi.price)
            AS gross_sales,
        COUNT(DISTINCT oi.order_item_id)
            AS total_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_items
    FROM products p
    JOIN categories c
        ON p.category_id = c.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY
        p.product_id,
        c.category_name
),
rates AS
(
    SELECT
        *,
        returned_items * 100.0 /
        NULLIF(total_items, 0)
            AS return_rate
    FROM product_metrics
),
benchmarked AS
(
    SELECT
        *,
        AVG(gross_sales) OVER ()
            AS avg_product_sales,

        AVG(return_rate) OVER ()
            AS avg_product_return_rate
    FROM rates
)
SELECT
    product_id,
    category_name,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        return_rate,
        2
    ) AS return_rate_pct,
    CASE
        WHEN gross_sales >= avg_product_sales
             AND return_rate <= avg_product_return_rate
            THEN 'High Revenue - Lower Return Risk'
        WHEN gross_sales >= avg_product_sales
             AND return_rate > avg_product_return_rate
            THEN 'High Revenue - Elevated Return Risk'
        WHEN gross_sales < avg_product_sales
             AND return_rate <= avg_product_return_rate
            THEN 'Lower Revenue - Lower Return Risk'
        ELSE 'Lower Revenue - Elevated Return Risk'
    END AS product_risk_segment
FROM benchmarked
ORDER BY gross_sales DESC;


--   =============================================================
--   BUSINESS QUESTION 35
--   How many products fall into each revenue/return-risk segment?

WITH product_metrics AS
(
    SELECT
        p.product_id,
        SUM(oi.qty * oi.price)
            AS gross_sales,
        COUNT(DISTINCT oi.order_item_id)
            AS total_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_items
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY p.product_id
),
rates AS
(
    SELECT
        *,
        returned_items * 100.0 /
        NULLIF(total_items, 0)
            AS return_rate
    FROM product_metrics
),
benchmarked AS
(
    SELECT
        *,
        AVG(gross_sales) OVER ()
            AS avg_sales,
        AVG(return_rate) OVER ()
            AS avg_return_rate
    FROM rates
),
segmented AS
(
    SELECT
        *,
        CASE
            WHEN gross_sales >= avg_sales
                 AND return_rate <= avg_return_rate
                THEN 'High Revenue - Lower Return Risk'
            WHEN gross_sales >= avg_sales
                 AND return_rate > avg_return_rate
                THEN 'High Revenue - Elevated Return Risk'
            WHEN gross_sales < avg_sales
                 AND return_rate <= avg_return_rate
                THEN 'Lower Revenue - Lower Return Risk'
            ELSE 'Lower Revenue - Elevated Return Risk'
        END AS product_segment
    FROM benchmarked
)
SELECT
    product_segment,
    COUNT(*) AS total_products,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS product_percentage
FROM segmented
GROUP BY product_segment
ORDER BY total_products DESC;


--   ============================================================
--   PART 4: CUSTOMER & PROMOTION INTELLIGENCE
--   ============================================================


--   ============================================================
--   BUSINESS QUESTION 36
--   Which customers generate the highest gross sales?

WITH customer_performance AS
(
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)
            AS total_orders,
        SUM(oi.qty)
            AS units_purchased,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    total_orders,
    units_purchased,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales /
        NULLIF(total_orders, 0),
        2
    ) AS avg_order_value,
    RANK() OVER (
        ORDER BY gross_sales DESC
    ) AS customer_value_rank
FROM customer_performance
ORDER BY customer_value_rank;


--   ============================================================
--   BUSINESS QUESTION 37
--   How concentrated is company revenue among customers?
-- 		Shows individual and cumulative customer contribution.

WITH customer_sales AS
(
    SELECT
        o.customer_id,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
contribution AS
(
    SELECT
        customer_id,
        gross_sales,
        gross_sales * 100.0 /
        SUM(gross_sales) OVER ()
            AS sales_contribution_pct,
        SUM(gross_sales) OVER (
            ORDER BY gross_sales DESC, customer_id
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) * 100.0 /
        SUM(gross_sales) OVER ()
            AS cumulative_sales_pct
    FROM customer_sales
)
SELECT
    customer_id,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        sales_contribution_pct,
        4
    ) AS sales_contribution_pct,
    ROUND(
        cumulative_sales_pct,
        2
    ) AS cumulative_sales_pct
FROM contribution
ORDER BY gross_sales DESC, customer_id;


--   ============================================================
--   BUSINESS QUESTION 38
--   How many customers generate approximately 80% of sales?
-- 		Customer Pareto/concentration analysis.
-- 		We calculate the actual number required rather than
-- 		assuming an 80/20 relationship exists.

WITH customer_sales AS
(
    SELECT
        o.customer_id,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
cumulative_analysis AS
(
    SELECT
        customer_id,
        gross_sales,
        SUM(gross_sales) OVER (
            ORDER BY gross_sales DESC, customer_id
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_sales,
        SUM(gross_sales) OVER ()
            AS total_sales
    FROM customer_sales
),
contribution AS
(
    SELECT
        *,
        cumulative_sales /
        NULLIF(total_sales, 0)
        * 100 AS cumulative_pct
    FROM cumulative_analysis
),
threshold AS
(
    SELECT
        MIN(cumulative_sales)
            AS threshold_sales
    FROM contribution
    WHERE cumulative_pct >= 80
)
SELECT
    COUNT(*) AS customers_required_for_80_pct_sales,
    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM customer_sales
        ),
        2
    ) AS pct_of_active_customers,
    ROUND(
        MAX(c.cumulative_pct),
        2
    ) AS cumulative_sales_pct
FROM contribution c
CROSS JOIN threshold t
WHERE c.cumulative_sales <= t.threshold_sales;


--   ============================================================
--   BUSINESS QUESTION 39
--   Which customers purchase most frequently?

WITH customer_frequency AS
(
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)
            AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_orders,
    RANK() OVER (
        ORDER BY total_orders DESC
    ) AS purchase_frequency_rank
FROM customer_frequency
ORDER BY
    purchase_frequency_rank,
    customer_id;


--   ============================================================
--   BUSINESS QUESTION 40
--   What percentage of active customers are repeat customers?
-- 		Repeat customer = customer with more than one order.

WITH customer_orders AS
(
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)
            AS total_orders
    FROM orders
    GROUP BY customer_id
),
customer_types AS
(
    SELECT
        customer_id,
        total_orders,
        CASE
            WHEN total_orders = 1
                THEN 'One-Time Customer'
            ELSE 'Repeat Customer'
        END AS customer_type
    FROM customer_orders
)
SELECT
    customer_type,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage
FROM customer_types
GROUP BY customer_type
ORDER BY total_customers DESC;


--   =============================================================
--   BUSINESS QUESTION 41
--   How much sales value comes from one-time vs repeat customers?

WITH customer_metrics AS
(
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)
            AS total_orders,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
customer_types AS
(
    SELECT
        customer_id,
        total_orders,
        gross_sales,
        CASE
            WHEN total_orders = 1
                THEN 'One-Time Customer'
            ELSE 'Repeat Customer'
        END AS customer_type
    FROM customer_metrics
),
segment_sales AS
(
    SELECT
        customer_type,
        COUNT(*) AS customers,
        SUM(gross_sales) AS gross_sales
    FROM customer_types
    GROUP BY customer_type
)
SELECT
    customer_type,
    customers,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (),
        2
    ) AS sales_contribution_pct,
    ROUND(
        gross_sales /
        NULLIF(customers, 0),
        2
    ) AS avg_sales_per_customer
FROM segment_sales
ORDER BY gross_sales DESC;


--   ========================================================================
--   BUSINESS QUESTION 42
--   How can customers be segmented using purchase frequency and gross sales?
-- 		Customers are benchmarked against the ACTIVE-customer averages for:
-- 		1. Number of orders
-- 		2. Gross sales
-- 		This is a behavioural/value segmentation, NOT an RFM model.

WITH customer_metrics AS
(
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)
            AS total_orders,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
benchmarked AS
(
    SELECT
        *,
        AVG(total_orders) OVER ()
            AS avg_customer_orders,
        AVG(gross_sales) OVER ()
            AS avg_customer_sales
    FROM customer_metrics
)
SELECT
    customer_id,
    total_orders,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    CASE
        WHEN total_orders >= avg_customer_orders
             AND gross_sales >= avg_customer_sales
            THEN 'High Frequency - High Value'
        WHEN total_orders >= avg_customer_orders
             AND gross_sales < avg_customer_sales
            THEN 'High Frequency - Lower Value'
        WHEN total_orders < avg_customer_orders
             AND gross_sales >= avg_customer_sales
            THEN 'Lower Frequency - High Value'
        ELSE 'Lower Frequency - Lower Value'
    END AS customer_segment
FROM benchmarked
ORDER BY gross_sales DESC;


--   ===================================================================================
--   BUSINESS QUESTION 43
--   How large is each customer segment and how much sales does each segment contribute?

WITH customer_metrics AS
(
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)
            AS total_orders,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
benchmarked AS
(
    SELECT
        *,
        AVG(total_orders) OVER ()
            AS avg_orders,
        AVG(gross_sales) OVER ()
            AS avg_sales
    FROM customer_metrics
),
segmented AS
(
    SELECT
        *,
        CASE
            WHEN total_orders >= avg_orders
                 AND gross_sales >= avg_sales
                THEN 'High Frequency - High Value'
            WHEN total_orders >= avg_orders
                 AND gross_sales < avg_sales
                THEN 'High Frequency - Lower Value'
            WHEN total_orders < avg_orders
                 AND gross_sales >= avg_sales
                THEN 'Lower Frequency - High Value'
            ELSE 'Lower Frequency - Lower Value'
        END AS customer_segment
    FROM benchmarked
),
segment_summary AS
(
    SELECT
        customer_segment,
        COUNT(*) AS total_customers,
        SUM(gross_sales) AS gross_sales
    FROM segmented
    GROUP BY customer_segment
)
SELECT
    customer_segment,
    total_customers,
    ROUND(
        total_customers * 100.0 /
        SUM(total_customers) OVER (),
        2
    ) AS customer_share_pct,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (),
        2
    ) AS sales_contribution_pct
FROM segment_summary
ORDER BY gross_sales DESC;


--   ==============================================================================
--   BUSINESS QUESTION 44
--   How does promotion-associated purchasing compare with non-promoted purchasing?
-- 		Order value is calculated first at order grain.
-- 		IMPORTANT:
-- 		Differences are descriptive associations.
-- 		They do NOT prove promotion effectiveness.

WITH order_metrics AS
(
    SELECT
        o.order_id,
        CASE
            WHEN o.promotion_id IS NULL
                THEN 'No Promotion'
            ELSE 'Promotion'
        END AS promotion_status,
        SUM(oi.qty)
            AS units_per_order,
        SUM(oi.qty * oi.price)
            AS gross_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.promotion_id
)
SELECT
    promotion_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct,
    ROUND(
        AVG(units_per_order),
        2
    ) AS avg_units_per_order,
    ROUND(
        AVG(gross_order_value),
        2
    ) AS avg_order_value,
    ROUND(
        SUM(gross_order_value),
        2
    ) AS gross_sales,
    ROUND(
        SUM(gross_order_value) * 100.0 /
        SUM(SUM(gross_order_value)) OVER (),
        2
    ) AS sales_share_pct
FROM order_metrics
GROUP BY promotion_status
ORDER BY gross_sales DESC;


--   ==========================================================================================
--   BUSINESS QUESTION 45
--   Which individual promotions are associated with the strongest order and sales performance?

WITH promotion_metrics AS
(
    SELECT
        p.promotion_id,
        p.discount,
        COUNT(DISTINCT o.order_id)
            AS total_orders,
        SUM(oi.qty)
            AS units_sold,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM promotions p
    LEFT JOIN orders o
        ON p.promotion_id = o.promotion_id
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        p.promotion_id,
        p.discount
)
SELECT
    promotion_id,
    discount,
    total_orders,
    units_sold,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales /
        NULLIF(total_orders, 0),
        2
    ) AS avg_order_value,
    RANK() OVER (
        ORDER BY gross_sales DESC
    ) AS promotion_sales_rank
FROM promotion_metrics
ORDER BY promotion_sales_rank;


--   ============================================================
--   BUSINESS QUESTION 46
--   How does customer purchasing behaviour vary across discount levels?
-- 		Multiple promotions may share a discount value.

WITH order_metrics AS
(
    SELECT
        o.order_id,
        o.customer_id,
        p.discount,
        SUM(oi.qty)
            AS units_per_order,
        SUM(oi.qty * oi.price)
            AS gross_order_value
    FROM orders o
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.customer_id,
        p.discount
)
SELECT
    discount,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id)
        AS unique_customers,
    ROUND(
        AVG(units_per_order),
        2
    ) AS avg_units_per_order,
    ROUND(
        AVG(gross_order_value),
        2
    ) AS avg_order_value,
    ROUND(
        SUM(gross_order_value),
        2
    ) AS gross_sales
FROM order_metrics
GROUP BY discount
ORDER BY discount;


--   ===================================================================================
--   BUSINESS QUESTION 47
--   Which discount levels are associated with above-average order values?
-- 		Discount-level AOV is benchmarked against the average AOV across PROMOTED orders.

WITH order_metrics AS
(
    SELECT
        o.order_id,
        p.discount,
        SUM(oi.qty * oi.price)
            AS order_value
    FROM orders o
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        p.discount
),
discount_metrics AS
(
    SELECT
        discount,
        COUNT(*) AS total_orders,
        AVG(order_value)
            AS avg_order_value
    FROM order_metrics
    GROUP BY discount
),
benchmarked AS
(
    SELECT
        *,
        (
            SELECT AVG(order_value)
            FROM order_metrics
        ) AS promoted_order_avg_value
    FROM discount_metrics
)
SELECT
    discount,
    total_orders,
    ROUND(
        avg_order_value,
        2
    ) AS avg_order_value,
    ROUND(
        promoted_order_avg_value,
        2
    ) AS promoted_order_avg_value,
    ROUND(
        (
            avg_order_value -
            promoted_order_avg_value
        )
        / NULLIF(
            promoted_order_avg_value,
            0
        )
        * 100,
        2
    ) AS difference_from_promoted_avg_pct,
    CASE
        WHEN avg_order_value >= promoted_order_avg_value
            THEN 'Above Promoted-Order Average'
        ELSE 'Below Promoted-Order Average'
    END AS aov_position
FROM benchmarked
ORDER BY avg_order_value DESC;


--   =================================================================================
--   BUSINESS QUESTION 48
--   Which categories generate the greatest sales through promotion-associated orders?

WITH category_promotion AS
(
    SELECT
        c.category_id,
        c.category_name,
        SUM(
            CASE
                WHEN o.promotion_id IS NOT NULL
                    THEN oi.qty * oi.price
                ELSE 0
            END
        ) AS promoted_sales,
        SUM(
            oi.qty * oi.price
        ) AS total_sales
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY
        c.category_id,
        c.category_name
)
SELECT
    category_id,
    category_name,
    ROUND(
        promoted_sales,
        2
    ) AS promoted_sales,
    ROUND(
        total_sales,
        2
    ) AS total_sales,
    ROUND(
        promoted_sales /
        NULLIF(total_sales, 0)
        * 100,
        2
    ) AS promoted_sales_share_pct,
    RANK() OVER (
        ORDER BY promoted_sales DESC
    ) AS promoted_sales_rank
FROM category_promotion
ORDER BY promoted_sales_rank;


--   ================================================================================
--   BUSINESS QUESTION 49
--   Within each category, how do promoted and non-promoted order-item sales compare?
-- 		Again: this identifies association, NOT causal uplift.

WITH category_promotion_sales AS
(
    SELECT
        c.category_id,
        c.category_name,
        CASE
            WHEN o.promotion_id IS NULL
                THEN 'No Promotion'
            ELSE 'Promotion'
        END AS promotion_status,
        COUNT(DISTINCT o.order_id)
            AS total_orders,
        SUM(oi.qty)
            AS units_sold,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY
        c.category_id,
        c.category_name,
        CASE
            WHEN o.promotion_id IS NULL
                THEN 'No Promotion'
            ELSE 'Promotion'
        END
)
SELECT
    category_id,
    category_name,
    promotion_status,
    total_orders,
    units_sold,
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (
            PARTITION BY category_id
        ),
        2
    ) AS category_sales_share_pct
FROM category_promotion_sales
ORDER BY
    category_name,
    gross_sales DESC;


--   ============================================================
--   BUSINESS QUESTION 50
--   Which customer segments account for the greatest promotion-associated sales?
-- 		First: segment customers using overall frequency/value.
-- 		Then: measure promotion-associated sales within each segment.

WITH customer_metrics AS
(
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)
            AS total_orders,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
benchmarked AS
(
    SELECT
        *,
        AVG(total_orders) OVER ()
            AS avg_orders,
        AVG(gross_sales) OVER ()
            AS avg_sales
    FROM customer_metrics
),
customer_segments AS
(
    SELECT
        customer_id,
        CASE

            WHEN total_orders >= avg_orders
                 AND gross_sales >= avg_sales
                THEN 'High Frequency - High Value'
            WHEN total_orders >= avg_orders
                 AND gross_sales < avg_sales
                THEN 'High Frequency - Lower Value'
            WHEN total_orders < avg_orders
                 AND gross_sales >= avg_sales
                THEN 'Lower Frequency - High Value'
            ELSE 'Lower Frequency - Lower Value'
        END AS customer_segment
    FROM benchmarked
),
promotion_sales AS
(
    SELECT
        o.customer_id,
        SUM(
            CASE
                WHEN o.promotion_id IS NOT NULL
                    THEN oi.qty * oi.price
                ELSE 0
            END
        ) AS promoted_sales,
        SUM(
            oi.qty * oi.price
        ) AS total_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)
SELECT
    cs.customer_segment,
    COUNT(*) AS total_customers,
    ROUND(
        SUM(ps.promoted_sales),
        2
    ) AS promoted_sales,
    ROUND(
        SUM(ps.total_sales),
        2
    ) AS total_sales,
    ROUND(
        SUM(ps.promoted_sales) /
        NULLIF(SUM(ps.total_sales), 0)
        * 100,
        2
    ) AS promoted_sales_share_pct
FROM customer_segments cs
JOIN promotion_sales ps
    ON cs.customer_id = ps.customer_id
GROUP BY cs.customer_segment
ORDER BY promoted_sales DESC;


--   ============================================================
--   PART 5: RETURNS, REFUNDS & OPERATIONAL PERFORMANCE
--   ============================================================


--   ============================================================
--   BUSINESS QUESTION 51
--   What is the company's overall return and refund exposure?

WITH sales_summary AS
(
    SELECT
        COUNT(DISTINCT order_item_id) AS total_order_items,
        SUM(qty * price) AS gross_sales
    FROM order_items
),
return_summary AS
(
    SELECT
        COUNT(DISTINCT order_item_id)
            AS returned_order_items,
        SUM(refund)
            AS total_refunds
    FROM returns
)
SELECT
    ss.total_order_items,
    rs.returned_order_items,
    ROUND(
        rs.returned_order_items * 100.0 /
        NULLIF(ss.total_order_items, 0),
        2
    ) AS return_rate_pct,
    ROUND(
        ss.gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        rs.total_refunds,
        2
    ) AS total_refunds,
    ROUND(
        rs.total_refunds * 100.0 /
        NULLIF(ss.gross_sales, 0),
        2
    ) AS refund_to_sales_pct,
    ROUND(
        ss.gross_sales - rs.total_refunds,
        2
    ) AS revenue_after_refunds
FROM sales_summary ss
CROSS JOIN return_summary rs;


--   ==========================================================================
--   BUSINESS QUESTION 52
--   How concentrated are refunds among returned order items?
-- 		Multiple return records are first aggregated to the order_item_id grain.

WITH item_refunds AS
(
    SELECT
        order_item_id,
        SUM(refund) AS total_refund
    FROM returns
    GROUP BY order_item_id
),
ranked_refunds AS
(
    SELECT
        order_item_id,
        total_refund,
        RANK() OVER (
            ORDER BY total_refund DESC
        ) AS refund_rank,
        SUM(total_refund) OVER (
            ORDER BY total_refund DESC, order_item_id
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_refund,
        SUM(total_refund) OVER ()
            AS company_refund
    FROM item_refunds
)
SELECT
    order_item_id,
    refund_rank,
    ROUND(
        total_refund,
        2
    ) AS total_refund,
    ROUND(
        total_refund * 100.0 /
        NULLIF(company_refund, 0),
        4
    ) AS refund_contribution_pct,
    ROUND(
        cumulative_refund * 100.0 /
        NULLIF(company_refund, 0),
        2
    ) AS cumulative_refund_pct
FROM ranked_refunds
ORDER BY
    total_refund DESC,
    order_item_id;


--   ============================================================================
--   BUSINESS QUESTION 53
--   How many returned items account for approximately 80% of total refund value?

WITH item_refunds AS
(
    SELECT
        order_item_id,
        SUM(refund) AS total_refund
    FROM returns
    GROUP BY order_item_id
),
cumulative_analysis AS
(
    SELECT
        order_item_id,
        total_refund,
        SUM(total_refund) OVER (
            ORDER BY total_refund DESC, order_item_id
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_refund,
        SUM(total_refund) OVER ()
            AS total_refunds
    FROM item_refunds
),
contribution AS
(
    SELECT
        *,
        cumulative_refund /
        NULLIF(total_refunds, 0)
        * 100 AS cumulative_pct
    FROM cumulative_analysis
),
threshold AS
(
    SELECT
        MIN(cumulative_refund)
            AS threshold_refund
    FROM contribution
    WHERE cumulative_pct >= 80
)
SELECT
    COUNT(*) AS returned_items_required_for_80_pct_refunds,
    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM item_refunds
        ),
        2
    ) AS pct_of_returned_items,
    ROUND(
        MAX(c.cumulative_pct),
        2
    ) AS cumulative_refund_pct
FROM contribution c
CROSS JOIN threshold t
WHERE c.cumulative_refund <= t.threshold_refund;


--   ============================================================
--   BUSINESS QUESTION 54
--   Which products create the greatest absolute refund exposure?

WITH product_refunds AS
(
    SELECT
        p.product_id,
        c.category_name,
        COUNT(DISTINCT r.order_item_id)
            AS returned_items,
        SUM(r.refund)
            AS total_refunds
    FROM returns r
    JOIN order_items oi
        ON r.order_item_id = oi.order_item_id
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN categories c
        ON p.category_id = c.category_id
    GROUP BY
        p.product_id,
        c.category_name
)
SELECT
    product_id,
    category_name,
    returned_items,
    ROUND(
        total_refunds,
        2
    ) AS total_refunds,
    RANK() OVER (
        ORDER BY total_refunds DESC
    ) AS refund_rank
FROM product_refunds
ORDER BY refund_rank;


--   =====================================================================
--   BUSINESS QUESTION 55
--   Which categories combine high return rates with high refund exposure?

WITH category_metrics AS
(
    SELECT
        c.category_id,
        c.category_name,
        COUNT(DISTINCT oi.order_item_id)
            AS total_order_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_items,
        COALESCE(
            SUM(r.refund),
            0
        ) AS total_refunds
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY
        c.category_id,
        c.category_name
),
rates AS
(
    SELECT
        *,
        returned_items * 100.0 /
        NULLIF(total_order_items, 0)
            AS return_rate
    FROM category_metrics
),
benchmarked AS
(
    SELECT
        *,
        AVG(return_rate) OVER ()
            AS avg_category_return_rate,
        AVG(total_refunds) OVER ()
            AS avg_category_refunds
    FROM rates
)
SELECT
    category_id,
    category_name,
    ROUND(
        return_rate,
        2
    ) AS return_rate_pct,
    ROUND(
        total_refunds,
        2
    ) AS total_refunds,
    CASE
        WHEN return_rate >= avg_category_return_rate
             AND total_refunds >= avg_category_refunds
            THEN 'High Return Rate - High Refund Exposure'
        WHEN return_rate >= avg_category_return_rate
             AND total_refunds < avg_category_refunds
            THEN 'High Return Rate - Lower Refund Exposure'
        WHEN return_rate < avg_category_return_rate
             AND total_refunds >= avg_category_refunds
            THEN 'Lower Return Rate - High Refund Exposure'
        ELSE 'Lower Return Rate - Lower Refund Exposure'
    END AS category_risk_segment
FROM benchmarked
ORDER BY total_refunds DESC;


--   ============================================================
--   BUSINESS QUESTION 56
--   What is the overall shipment-status profile?

SELECT
    status,
    COUNT(*) AS total_shipments,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS shipment_share_pct
FROM shipments
GROUP BY status
ORDER BY total_shipments DESC;


--   ============================================================
--   BUSINESS QUESTION 57
--   How does return rate differ by shipment status?
-- 		IMPORTANT: This shows association only.
-- 		It does NOT prove that a shipment status caused a return.

WITH shipment_returns AS
(
    SELECT
        sh.status,
        COUNT(DISTINCT oi.order_item_id)
            AS total_order_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_items
    FROM shipments sh
    JOIN orders o
        ON sh.order_id = o.order_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY sh.status
)
SELECT
    status,
    total_order_items,
    returned_items,
    ROUND(
        returned_items * 100.0 /
        NULLIF(total_order_items, 0),
        2
    ) AS return_rate_pct,
    RANK() OVER (
        ORDER BY
            returned_items * 1.0 /
            NULLIF(total_order_items, 0)
        DESC
    ) AS return_rate_rank
FROM shipment_returns
ORDER BY return_rate_rank;


--   ========================================================================
--   BUSINESS QUESTION 58
--   How much sales and refund value is associated with each shipment status?

WITH shipment_sales AS
(
    SELECT
        sh.status,
        COUNT(DISTINCT o.order_id)
            AS total_orders,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM shipments sh
    JOIN orders o
        ON sh.order_id = o.order_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY sh.status
),
shipment_refunds AS
(
    SELECT
        sh.status,
        SUM(r.refund)
            AS total_refunds
    FROM shipments sh
    JOIN orders o
        ON sh.order_id = o.order_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY sh.status
)
SELECT
    ss.status,
    ss.total_orders,
    ROUND(
        ss.gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        COALESCE(sr.total_refunds, 0),
        2
    ) AS total_refunds,
    ROUND(
        COALESCE(sr.total_refunds, 0) * 100.0 /
        NULLIF(ss.gross_sales, 0),
        2
    ) AS refund_to_sales_pct
FROM shipment_sales ss
LEFT JOIN shipment_refunds sr
    ON ss.status = sr.status
ORDER BY refund_to_sales_pct DESC;


--   ======================================================================================
--   BUSINESS QUESTION 59
--   Which stores have the greatest combined return and late-shipment operational exposure?

WITH store_returns AS
(
    SELECT
        o.store_id,
        COUNT(DISTINCT oi.order_item_id)
            AS total_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_items
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY o.store_id
),
store_shipments AS
(
    SELECT
        o.store_id,
        COUNT(*) AS total_shipments,
        SUM(
            CASE
                WHEN sh.status = 'LATE'
                    THEN 1
                ELSE 0
            END
        ) AS late_shipments
    FROM orders o
    JOIN shipments sh
        ON o.order_id = sh.order_id
    GROUP BY o.store_id
),
store_metrics AS
(
    SELECT
        sr.store_id,
        sr.returned_items * 100.0 /
        NULLIF(sr.total_items, 0)
            AS return_rate,
        ss.late_shipments * 100.0 /
        NULLIF(ss.total_shipments, 0)
            AS late_shipment_rate
    FROM store_returns sr
    JOIN store_shipments ss
        ON sr.store_id = ss.store_id
),
benchmarked AS
(
    SELECT
        *,
        AVG(return_rate) OVER ()
            AS avg_return_rate,
        AVG(late_shipment_rate) OVER ()
            AS avg_late_rate
    FROM store_metrics
)
SELECT
    s.store_id,
    s.city,
    ROUND(
        b.return_rate,
        2
    ) AS return_rate_pct,
    ROUND(
        b.late_shipment_rate,
        2
    ) AS late_shipment_rate_pct,
    CASE
        WHEN b.return_rate > b.avg_return_rate
             AND b.late_shipment_rate > b.avg_late_rate
            THEN 'High Return & High Late-Shipment Risk'
        WHEN b.return_rate > b.avg_return_rate
            THEN 'Elevated Return Risk'
        WHEN b.late_shipment_rate > b.avg_late_rate
            THEN 'Elevated Late-Shipment Risk'
        ELSE 'Lower Operational Risk'
    END AS operational_risk_segment
FROM benchmarked b
JOIN stores s
    ON b.store_id = s.store_id
ORDER BY
    b.return_rate DESC,
    b.late_shipment_rate DESC;


--   ============================================================
--   BUSINESS QUESTION 60
--   How many stores fall into each operational-risk segment?

WITH store_returns AS
(
    SELECT
        o.store_id,
        COUNT(DISTINCT oi.order_item_id)
            AS total_items,
        COUNT(DISTINCT r.order_item_id)
            AS returned_items
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id
    GROUP BY o.store_id
),
store_shipments AS
(
    SELECT
        o.store_id,
        COUNT(*) AS total_shipments,
        SUM(
            CASE
                WHEN sh.status = 'LATE'
                    THEN 1
                ELSE 0
            END
        ) AS late_shipments
    FROM orders o
    JOIN shipments sh
        ON o.order_id = sh.order_id
    GROUP BY o.store_id
),
metrics AS
(
    SELECT
        sr.store_id,
        sr.returned_items * 100.0 /
        NULLIF(sr.total_items, 0)
            AS return_rate,
        ss.late_shipments * 100.0 /
        NULLIF(ss.total_shipments, 0)
            AS late_rate
    FROM store_returns sr
    JOIN store_shipments ss
        ON sr.store_id = ss.store_id
),
benchmarked AS
(
    SELECT
        *,
        AVG(return_rate) OVER ()
            AS avg_return_rate,
        AVG(late_rate) OVER ()
            AS avg_late_rate
    FROM metrics
),
segmented AS
(
    SELECT
        *,
        CASE
            WHEN return_rate > avg_return_rate
                 AND late_rate > avg_late_rate
                THEN 'High Return & High Late-Shipment Risk'
            WHEN return_rate > avg_return_rate
                THEN 'Elevated Return Risk'
            WHEN late_rate > avg_late_rate
                THEN 'Elevated Late-Shipment Risk'
            ELSE 'Lower Operational Risk'
        END AS risk_segment
    FROM benchmarked
)
SELECT
    risk_segment,
    COUNT(*) AS total_stores,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS store_percentage
FROM segmented
GROUP BY risk_segment
ORDER BY total_stores DESC;


--   =====================================================================
--   BUSINESS QUESTION 61
--   Which stores retain the greatest revenue after recorded refunds?
-- 		Revenue after refunds = Gross transaction sales - recorded refunds
-- 		This is NOT profit.

WITH store_sales AS
(
    SELECT
        o.store_id,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.store_id
),
store_refunds AS
(
    SELECT
        o.store_id,
        SUM(r.refund)
            AS total_refunds
    FROM returns r
    JOIN order_items oi
        ON r.order_item_id = oi.order_item_id
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY o.store_id
),
store_net_revenue AS
(
    SELECT
        ss.store_id,
        ss.gross_sales,
        COALESCE(sr.total_refunds, 0)
            AS total_refunds,
        ss.gross_sales -
        COALESCE(sr.total_refunds, 0)
            AS revenue_after_refunds
    FROM store_sales ss
    LEFT JOIN store_refunds sr
        ON ss.store_id = sr.store_id
)
SELECT
    s.store_id,
    s.city,
    ROUND(
        sn.gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        sn.total_refunds,
        2
    ) AS total_refunds,
    ROUND(
        sn.revenue_after_refunds,
        2
    ) AS revenue_after_refunds,
    RANK() OVER (
        ORDER BY sn.revenue_after_refunds DESC
    ) AS revenue_after_refunds_rank
FROM store_net_revenue sn
JOIN stores s
    ON sn.store_id = s.store_id
ORDER BY revenue_after_refunds_rank;


--   ====================================================================
--   BUSINESS QUESTION 62
--   Which categories retain the greatest revenue after recorded refunds?

WITH category_sales AS
(
    SELECT
        c.category_id,
        c.category_name,
        SUM(oi.qty * oi.price)
            AS gross_sales
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        c.category_id,
        c.category_name
),
category_refunds AS
(
    SELECT
        p.category_id,
        SUM(r.refund)
            AS total_refunds
    FROM returns r
    JOIN order_items oi
        ON r.order_item_id = oi.order_item_id
    JOIN products p
        ON oi.product_id = p.product_id

    GROUP BY p.category_id
)
SELECT
    cs.category_id,
    cs.category_name,
    ROUND(
        cs.gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        COALESCE(cr.total_refunds, 0),
        2
    ) AS total_refunds,
    ROUND(
        cs.gross_sales -
        COALESCE(cr.total_refunds, 0),
        2
    ) AS revenue_after_refunds,
    ROUND(
        COALESCE(cr.total_refunds, 0)
        * 100.0 /
        NULLIF(cs.gross_sales, 0),
        2
    ) AS refund_to_sales_pct
FROM category_sales cs
LEFT JOIN category_refunds cr
    ON cs.category_id = cr.category_id
ORDER BY revenue_after_refunds DESC;


--   ============================================================
--   BUSINESS QUESTION 63
--   What is the executive operational-health summary?
-- 		Final high-level operational metrics for management.
-- 		NOTE:
-- 		late shipment rate is based on shipment records.
-- 		return rate is based on distinct order-item records.
-- 		These metrics therefore have different denominators.

WITH sales_summary AS
(
    SELECT
        SUM(qty * price)
            AS gross_sales,
        COUNT(DISTINCT order_item_id)
            AS total_order_items
    FROM order_items
),
refund_summary AS
(
    SELECT
        COUNT(DISTINCT order_item_id)
            AS returned_items,
        SUM(refund)
            AS total_refunds
    FROM returns
),
shipment_summary AS
(
    SELECT
        COUNT(*) AS total_shipments,
        SUM(
            CASE
                WHEN status = 'LATE'
                    THEN 1
                ELSE 0
            END
        ) AS late_shipments
    FROM shipments
)
SELECT
    ROUND(
        ss.gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        rs.total_refunds,
        2
    ) AS total_refunds,
    ROUND(
        ss.gross_sales - rs.total_refunds,
        2
    ) AS revenue_after_refunds,
    ROUND(
        rs.total_refunds * 100.0 /
        NULLIF(ss.gross_sales, 0),
        2
    ) AS refund_to_sales_pct,
    ROUND(
        rs.returned_items * 100.0 /
        NULLIF(ss.total_order_items, 0),
        2
    ) AS order_item_return_rate_pct,
    ROUND(
        sh.late_shipments * 100.0 /
        NULLIF(sh.total_shipments, 0),
        2
    ) AS late_shipment_rate_pct
FROM sales_summary ss
CROSS JOIN refund_summary rs
CROSS JOIN shipment_summary sh;




/* ======================= END OF FILE ======================== */