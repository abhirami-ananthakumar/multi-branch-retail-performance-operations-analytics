
--   ==================================================================
--   PROJECT: MULTI-BRANCH RETAIL PERFORMANCE & REVENUE INTELLIGENCE
--   DATABASE: MySQL 8.0
--   FILE: 04_EDA.sql
--   PURPOSE:
--   Explore the cleaned retail dataset to understand:
--   - Dataset scale
--   - Transaction period
--   - Sales behaviour
--   - Order behaviour
--   - Customer activity
--   - Store performance
--   - Product/category performance
--   - Promotions
--   - Returns
--   - Shipment performance

--   IMPORTANT DATA QUALITY NOTE:
--   120,020 orders occur before the associated customer signup_date.
--   Therefore signup_date is excluded from customer tenure,
--   acquisition and pre/post-signup analysis.
--   ==================================================================


USE retail_dw;


--   ============================================================
--   PART 1: DATASETS AND SALES OVERVIEW
--   ============================================================


--   ============================================================
--   1.1 DATASET SCALE

SELECT 'categories' AS table_name, COUNT(*) AS row_count
FROM categories
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'promotions', COUNT(*) FROM promotions
UNION ALL
SELECT 'returns', COUNT(*) FROM returns
UNION ALL
SELECT 'shipments', COUNT(*) FROM shipments
UNION ALL
SELECT 'stores', COUNT(*) FROM stores
UNION ALL
SELECT 'suppliers', COUNT(*) FROM suppliers
ORDER BY row_count DESC;


--   ============================================================
--   1.2 TRANSACTION DATE RANGE

SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS analysis_period_days,
    COUNT(DISTINCT YEAR(order_date)) AS years_covered
FROM orders;


--   ============================================================
--   1.3 ORDERS BY YEAR

SELECT
    YEAR(order_date) AS order_year,
    COUNT(*) AS total_orders
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;


--   ============================================================
--   1.4 ORDER ITEM PROFILE

SELECT
    COUNT(*) AS total_order_lines,
    SUM(qty) AS total_units_sold,
    ROUND(AVG(qty), 2) AS avg_qty_per_line,
    MIN(qty) AS min_qty,
    MAX(qty) AS max_qty,
    ROUND(AVG(price), 2) AS avg_selling_price,
    MIN(price) AS min_selling_price,
    MAX(price) AS max_selling_price
FROM order_items;


--   ============================================================
--   1.5 ORDER SIZE PROFILE

WITH order_summary AS
(
    SELECT
        order_id,
        COUNT(*) AS line_items,
        SUM(qty) AS units
    FROM order_items
    GROUP BY order_id
)
SELECT
    COUNT(*) AS orders_with_items,
    ROUND(AVG(line_items), 2) AS avg_lines_per_order,
    MIN(line_items) AS min_lines_per_order,
    MAX(line_items) AS max_lines_per_order,
    ROUND(AVG(units), 2) AS avg_units_per_order,
    MIN(units) AS min_units_per_order,
    MAX(units) AS max_units_per_order
FROM order_summary;


--   ============================================================
--   1.6 GROSS SALES PROFILE
--   Gross sales = qty × transaction price
--   IMPORTANT:
--   	This is revenue/sales, NOT profit.
--  	No product cost / COGS field exists in the dataset.

SELECT
    ROUND(SUM(qty * price), 2) AS gross_sales,
    ROUND(AVG(qty * price), 2) AS avg_order_line_value,
    ROUND(MIN(qty * price), 2) AS smallest_order_line_value,
    ROUND(MAX(qty * price), 2) AS largest_order_line_value
FROM order_items;


--   ============================================================
--   1.7 ORDER VALUE PROFILE

WITH order_value AS
(
    SELECT
        order_id,
        SUM(qty * price) AS gross_order_value
    FROM order_items
    GROUP BY order_id
)
SELECT
    COUNT(*) AS total_orders,
    ROUND(SUM(gross_order_value), 2) AS gross_sales,
    ROUND(AVG(gross_order_value), 2) AS avg_order_value,
    ROUND(MIN(gross_order_value), 2) AS minimum_order_value,
    ROUND(MAX(gross_order_value), 2) AS maximum_order_value
FROM order_value;


--   ============================================================
--   1.8 CUSTOMER ORDER ACTIVITY
--   signup_date deliberately excluded because of the previously
--   documented temporal inconsistency.

WITH customer_activity AS
(
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS customers_with_orders,
    ROUND(AVG(order_count), 2) AS avg_orders_per_customer,
    MIN(order_count) AS min_orders_per_customer,
    MAX(order_count) AS max_orders_per_customer
FROM customer_activity;


--   ============================================================
--   1.9 PAYMENT PROFILE

SELECT
    COUNT(*) AS payment_records,
    ROUND(SUM(amount), 2) AS total_payment_amount,
    ROUND(AVG(amount), 2) AS avg_payment_amount,
    MIN(amount) AS minimum_payment,
    MAX(amount) AS maximum_payment
FROM payments;


--   ============================================================
--   1.10 RETURNS PROFILE

SELECT
    COUNT(*) AS total_return_records,
    COUNT(DISTINCT order_item_id) AS distinct_returned_order_items,
    ROUND(SUM(refund), 2) AS total_refund_amount,
    ROUND(AVG(refund), 2) AS avg_refund_amount,
    MIN(refund) AS minimum_refund,
    MAX(refund) AS maximum_refund
FROM returns;


--   ============================================================
--   1.11 SHIPMENT STATUS DISTRIBUTION

SELECT
    status,
    COUNT(*) AS shipment_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS shipment_percentage
FROM shipments
GROUP BY status
ORDER BY shipment_count DESC;


--   ============================================================
--   PART 2: TIME-SERIES EXPLORATORY ANALYSIS
--   ============================================================


--   =========================================================================
--   2.1 YEARLY SALES TREND
--   Explore how order volume, units sold and gross sales change across years.

SELECT
    YEAR(o.order_date) AS order_year,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS units_sold,
    ROUND(SUM(oi.qty * oi.price), 2) AS gross_sales,
    ROUND(
        SUM(oi.qty * oi.price) /
        COUNT(DISTINCT o.order_id),
        2
    ) AS avg_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY YEAR(o.order_date)
ORDER BY order_year;


--   ============================================================
--   2.2 MONTHLY SALES TREND

SELECT
    YEAR(o.order_date) AS order_year,
    MONTH(o.order_date) AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS units_sold,
    ROUND(SUM(oi.qty * oi.price), 2) AS gross_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date)
ORDER BY
    order_year,
    order_month;


--   ============================================================
--   2.3 MONTH-OVER-MONTH SALES GROWTH
--   LAG() retrieves the previous month's sales.
--   MoM Growth % =
--   (Current Month - Previous Month)
--   -------------------------------- × 100
--            Previous Month

WITH monthly_sales AS
(
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS sales_month,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        DATE_FORMAT(o.order_date, '%Y-%m-01')
),
monthly_comparison AS
(
    SELECT
        sales_month,
        gross_sales,
        LAG(gross_sales) OVER (
            ORDER BY sales_month
        ) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    sales_month,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(previous_month_sales, 2) AS previous_month_sales,
    ROUND(
        (gross_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0)
        * 100,
        2
    ) AS mom_growth_pct
FROM monthly_comparison
ORDER BY sales_month;


--   ============================================================
--   2.4 YEAR-OVER-YEAR MONTHLY SALES GROWTH
--   Compare a month with the SAME month one year earlier.
--   Example:
--   January 2023 vs January 2022

WITH monthly_sales AS
(
    SELECT
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date)
),
yoy_comparison AS
(
    SELECT
        order_year,
        order_month,
        gross_sales,
        LAG(gross_sales) OVER (
            PARTITION BY order_month
            ORDER BY order_year
        ) AS previous_year_sales
    FROM monthly_sales
)
SELECT
    order_year,
    order_month,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(previous_year_sales, 2) AS previous_year_sales,
    ROUND(
        (gross_sales - previous_year_sales)
        / NULLIF(previous_year_sales, 0)
        * 100,
        2
    ) AS yoy_growth_pct
FROM yoy_comparison
ORDER BY
    order_year,
    order_month;


--   ============================================================================
--   2.5 3-MONTH ROLLING AVERAGE SALES
--   Smooths short-term fluctuations and helps expose the underlying sales trend.
--   Current month + previous 2 months.

WITH monthly_sales AS
(
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS sales_month,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        DATE_FORMAT(o.order_date, '%Y-%m-01')
)
SELECT
    sales_month,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(
        AVG(gross_sales) OVER (
            ORDER BY sales_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3_month_avg
FROM monthly_sales
ORDER BY sales_month;


--   ============================================================
--   2.6 MONTH-OF-YEAR SEASONALITY
--   Combines the same month across all years.
--   This helps identify whether particular months tend to 
--   generate higher or lower sales.

SELECT
    MONTH(o.order_date) AS month_number,
    MONTHNAME(o.order_date) AS month_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS units_sold,
    ROUND(
        SUM(oi.qty * oi.price),
        2
    ) AS gross_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    MONTH(o.order_date),
    MONTHNAME(o.order_date)
ORDER BY month_number;


--   ============================================================
--   2.7 DAY-OF-WEEK SALES PATTERN
--   Determine whether sales/order activity differs by weekday.
--   WEEKDAY():
--   Monday = 0 ... Sunday = 6

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
    ) AS avg_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    WEEKDAY(o.order_date),
    DAYNAME(o.order_date)
ORDER BY weekday_number;


--   ============================================================
--   2.8 QUARTERLY SALES TREND

SELECT
    YEAR(o.order_date) AS order_year,
    QUARTER(o.order_date) AS order_quarter,
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
    ) AS avg_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    YEAR(o.order_date),
    QUARTER(o.order_date)
ORDER BY
    order_year,
    order_quarter;


--   ============================================================
--   2.9 CUMULATIVE SALES
--   Running total shows how gross sales accumulate
--   throughout the dataset period.

WITH monthly_sales AS
(
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS sales_month,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        DATE_FORMAT(o.order_date, '%Y-%m-01')
)
SELECT
    sales_month,
    ROUND(gross_sales, 2) AS monthly_sales,
    ROUND(
        SUM(gross_sales) OVER (
            ORDER BY sales_month
        ),
        2
    ) AS cumulative_sales
FROM monthly_sales
ORDER BY sales_month;


--   ============================================================
--   PART 3: CUSTOMER & STORE EXPLORATORY DATA ANALYSIS
--   ============================================================

--   ============================================================
--   3.1 CUSTOMER DISTRIBUTION BY CITY
--   Purpose: Understand where the customer base is concentrated.

SELECT
    city,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage
FROM customers
GROUP BY city
ORDER BY total_customers DESC;


--   ============================================================
--   3.2 CUSTOMER SIGNUPS BY YEAR
--   Purpose: Examine growth of the customer base over time.

SELECT
    YEAR(signup_date) AS signup_year,
    COUNT(*) AS new_customers
FROM customers
GROUP BY YEAR(signup_date)
ORDER BY signup_year;


--   =================================================================
--   3.3 CUSTOMER SIGNUPS BY MONTH
--   Purpose: Identify periods with higher/lower customer acquisition.

SELECT
    DATE_FORMAT(signup_date, '%Y-%m') AS signup_month,
    COUNT(*) AS new_customers
FROM customers
GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
ORDER BY signup_month;


--   ============================================================
--   3.4 ORDERS PER CUSTOMER DISTRIBUTION
--   Purpose: Understand customer purchase frequency.

SELECT
    customer_id,
    COUNT(*) AS total_orders
FROM orders
GROUP BY customer_id
ORDER BY total_orders DESC;


--   ============================================================
--   3.5 CUSTOMER ORDER FREQUENCY SUMMARY
--   Purpose: Summarize the distribution found above.

WITH customer_orders AS
(
    SELECT
        customer_id,
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS customers_with_orders,
    ROUND(AVG(total_orders), 2) AS avg_orders_per_customer,
    MIN(total_orders) AS min_orders_per_customer,
    MAX(total_orders) AS max_orders_per_customer
FROM customer_orders;


--   =================================================================
--   3.6 CUSTOMERS WITH NO ORDERS
--   Purpose: Identify registered customers who never placed an order.

SELECT
    COUNT(*) AS customers_without_orders
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;


--   ==============================================================
--   3.7 CUSTOMER SALES DISTRIBUTION
--   Purpose: Explore how much gross sales each customer generates.
--   Gross sales here: qty * order-item price

SELECT
    o.customer_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS units_purchased,
    ROUND(SUM(oi.qty * oi.price), 2) AS gross_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id
ORDER BY gross_sales DESC;


--   ==================================================================
--   3.8 CUSTOMER SALES SUMMARY
--   Purpose: Measure the overall spread of customer-level gross sales.

WITH customer_sales AS
(
    SELECT
        o.customer_id,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)
SELECT
    COUNT(*) AS customers_with_sales,
    ROUND(AVG(gross_sales), 2) AS avg_sales_per_customer,
    ROUND(MIN(gross_sales), 2) AS min_sales_per_customer,
    ROUND(MAX(gross_sales), 2) AS max_sales_per_customer
FROM customer_sales;


--   ============================================================
--   3.9 STORE DISTRIBUTION BY CITY
--   Purpose: Understand the geographic distribution of branches.

SELECT
    city,
    COUNT(*) AS total_stores
FROM stores
GROUP BY city
ORDER BY total_stores DESC;


--   ============================================================
--   3.10 STORE ORDER VOLUME
--   Purpose: Compare order activity across stores.

SELECT
    s.store_id,
    s.city,
    COUNT(o.order_id) AS total_orders
FROM stores s
LEFT JOIN orders o
    ON s.store_id = o.store_id
GROUP BY
    s.store_id,
    s.city
ORDER BY total_orders DESC;


--   ============================================================
--   3.11 STORE SALES PERFORMANCE
--   Purpose: Explore gross sales and units sold across stores.

SELECT
    s.store_id,
    s.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(oi.qty), 0) AS units_sold,
    ROUND(
        COALESCE(SUM(oi.qty * oi.price), 0),
        2
    ) AS gross_sales
FROM stores s
LEFT JOIN orders o
    ON s.store_id = o.store_id
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    s.store_id,
    s.city
ORDER BY gross_sales DESC;


--   ============================================================
--   3.12 STORE AVERAGE ORDER VALUE
--   Purpose: Compare average transaction size between stores.

WITH order_values AS
(
    SELECT
        o.order_id,
        o.store_id,
        SUM(oi.qty * oi.price) AS order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.store_id
)
SELECT
    s.store_id,
    s.city,
    COUNT(ov.order_id) AS total_orders,
    ROUND(AVG(ov.order_value), 2) AS avg_order_value
FROM stores s
LEFT JOIN order_values ov
    ON s.store_id = ov.store_id
GROUP BY
    s.store_id,
    s.city
ORDER BY avg_order_value DESC;


--   ============================================================
--   3.13 STORE EMPLOYEE DISTRIBUTION
--   Purpose: Explore workforce distribution across branches.

SELECT
    s.store_id,
    s.city,
    COUNT(e.employee_id) AS total_employees
FROM stores s
LEFT JOIN employees e
    ON s.store_id = e.store_id
GROUP BY
    s.store_id,
    s.city
ORDER BY total_employees DESC;


--   ============================================================
--  3.14 STORE SALARY PROFILE
--   Purpose: Compare employee salary structure across stores.

SELECT
    s.store_id,
    s.city,
    COUNT(e.employee_id) AS total_employees,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    ROUND(MIN(e.salary), 2) AS min_salary,
    ROUND(MAX(e.salary), 2) AS max_salary,
    ROUND(SUM(e.salary), 2) AS total_salary
FROM stores s
LEFT JOIN employees e
    ON s.store_id = e.store_id
GROUP BY
    s.store_id,
    s.city
ORDER BY total_salary DESC;


--   ===================================================================================
--   3.15 STORE PERFORMANCE SUMMARY
--   Purpose: Combine major store-level operational metrics into one exploratory output.
--   IMPORTANT:
--  	Employee data is aggregated separately before joining.
--  	This prevents employee rows from multiplying sales rows.

WITH store_sales AS
(
    SELECT
        o.store_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.qty) AS units_sold,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.store_id
),
store_employees AS
(
    SELECT
        store_id,
        COUNT(*) AS total_employees,
        SUM(salary) AS total_salary
    FROM employees
    GROUP BY store_id
)
SELECT
    s.store_id,
    s.city,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.units_sold, 0) AS units_sold,
    ROUND(
        COALESCE(ss.gross_sales, 0),
        2
    ) AS gross_sales,
    COALESCE(se.total_employees, 0) AS total_employees,
    ROUND(
        COALESCE(se.total_salary, 0),
        2
    ) AS total_salary
FROM stores s
LEFT JOIN store_sales ss
    ON s.store_id = ss.store_id
LEFT JOIN store_employees se
    ON s.store_id = se.store_id
ORDER BY gross_sales DESC;


--   ============================================================
--   PART 4: PRODUCT, CATEGORY & SUPPLIER EDA
--   ============================================================


--   ============================================================
--   4.1 PRODUCT DISTRIBUTION BY CATEGORY
--   Understand how the product catalog is distributed
--   across categories.

SELECT
    c.category_id,
    c.category_name,
    COUNT(p.product_id) AS total_products,
    ROUND(
        COUNT(p.product_id) * 100.0 /
        SUM(COUNT(p.product_id)) OVER (),
        2
    ) AS product_percentage
FROM categories c
LEFT JOIN products p
    ON c.category_id = p.category_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY total_products DESC;


--   ============================================================
--   4.2 PRODUCT MASTER PRICE DISTRIBUTION
--   Explore the overall price range of the product catalog.

SELECT
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_product_price,
    ROUND(MIN(price), 2) AS minimum_product_price,
    ROUND(MAX(price), 2) AS maximum_product_price
FROM products;


--   ============================================================
--   4.3 PRODUCT PRICE PROFILE BY CATEGORY
--   Compare master-product pricing across categories.

SELECT
    c.category_id,
    c.category_name,
    COUNT(p.product_id) AS total_products,
    ROUND(AVG(p.price), 2) AS avg_product_price,
    ROUND(MIN(p.price), 2) AS minimum_product_price,
    ROUND(MAX(p.price), 2) AS maximum_product_price
FROM categories c
LEFT JOIN products p
    ON c.category_id = p.category_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY avg_product_price DESC;


--   ============================================================
--   4.4 TRANSACTION PRICE PROFILE
--   Explore actual selling prices recorded in order_items.

SELECT
    COUNT(*) AS total_order_lines,
    ROUND(AVG(price), 2) AS avg_transaction_price,
    ROUND(MIN(price), 2) AS minimum_transaction_price,
    ROUND(MAX(price), 2) AS maximum_transaction_price
FROM order_items;


--   ============================================================
--   4.5 PRODUCT SALES DISTRIBUTION
--   Explore sales activity for each product.
--   LEFT JOIN is used so products with no sales can still
--   appear in the output.

SELECT
    p.product_id,
    c.category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COALESCE(SUM(oi.qty), 0) AS units_sold,
    ROUND(
        COALESCE(SUM(oi.qty * oi.price), 0),
        2
    ) AS gross_sales
FROM products p
LEFT JOIN categories c
    ON p.category_id = c.category_id
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    c.category_name
ORDER BY gross_sales DESC;


--   ============================================================
--   4.6 PRODUCT SALES SUMMARY
--   Summarize the distribution of sales across products.

WITH product_sales AS
(
    SELECT
        p.product_id,
        COALESCE(SUM(oi.qty), 0) AS units_sold,
        COALESCE(
            SUM(oi.qty * oi.price),
            0
        ) AS gross_sales
    FROM products p
    LEFT JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY p.product_id
)
SELECT
    COUNT(*) AS total_products,
    ROUND(AVG(units_sold), 2) AS avg_units_per_product,
    MIN(units_sold) AS min_units_per_product,
    MAX(units_sold) AS max_units_per_product,
    ROUND(AVG(gross_sales), 2) AS avg_sales_per_product,
    ROUND(MIN(gross_sales), 2) AS min_sales_per_product,
    ROUND(MAX(gross_sales), 2) AS max_sales_per_product
FROM product_sales;


--   ============================================================
--   4.7 PRODUCTS WITH NO SALES
--   Identify catalog products that never appear in order_items.

SELECT
    COUNT(*) AS products_without_sales
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE oi.order_item_id IS NULL;


--   ============================================================
--   4.8 CATEGORY SALES PERFORMANCE
--   Explore order activity, units and gross sales by category.

SELECT
    c.category_id,
    c.category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COALESCE(SUM(oi.qty), 0) AS units_sold,
    ROUND(
        COALESCE(SUM(oi.qty * oi.price), 0),
        2
    ) AS gross_sales
FROM categories c
LEFT JOIN products p
    ON c.category_id = p.category_id
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY gross_sales DESC;


--   ============================================================
--   4.9 CATEGORY SALES CONTRIBUTION
--   Calculate each category's percentage contribution
--   to total gross sales.

WITH category_sales AS
(
    SELECT
        c.category_id,
        c.category_name,
        SUM(oi.qty * oi.price) AS gross_sales
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
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (),
        2
    ) AS sales_contribution_pct
FROM category_sales
ORDER BY gross_sales DESC;


--   ============================================================
--   4.10 CATEGORY AVERAGE TRANSACTION PRICE
--   Compare actual selling prices across categories.

SELECT
    c.category_id,
    c.category_name,
    COUNT(*) AS order_lines,
    ROUND(AVG(oi.price), 2) AS avg_transaction_price,
    ROUND(MIN(oi.price), 2) AS minimum_transaction_price,
    ROUND(MAX(oi.price), 2) AS maximum_transaction_price
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN categories c
    ON p.category_id = c.category_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY avg_transaction_price DESC;


--   ============================================================
--   4.11 SUPPLIER DISTRIBUTION BY COUNTRY
--   Understand geographic distribution of suppliers.

SELECT
    country,
    COUNT(*) AS total_suppliers,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS supplier_percentage
FROM suppliers
GROUP BY country
ORDER BY total_suppliers DESC;


--   ============================================================
--   4.12 PRODUCTS PER SUPPLIER
--   Explore how many products are associated with each supplier.

SELECT
    s.supplier_id,
    s.country,
    COUNT(p.product_id) AS total_products
FROM suppliers s
LEFT JOIN products p
    ON s.supplier_id = p.supplier_id
GROUP BY
    s.supplier_id,
    s.country
ORDER BY total_products DESC;


--   ============================================================
--   4.13 SUPPLIER PRODUCT DISTRIBUTION SUMMARY
--   Summarize number of products supplied per supplier.

WITH supplier_products AS
(
    SELECT
        s.supplier_id,
        COUNT(p.product_id) AS total_products
    FROM suppliers s
    LEFT JOIN products p
        ON s.supplier_id = p.supplier_id
    GROUP BY s.supplier_id
)
SELECT
    COUNT(*) AS total_suppliers,
    ROUND(
        AVG(total_products),
        2
    ) AS avg_products_per_supplier,
    MIN(total_products) AS min_products_per_supplier,
    MAX(total_products) AS max_products_per_supplier
FROM supplier_products;


--   ============================================================
--   4.14 SUPPLIER SALES DISTRIBUTION
--   Explore gross sales generated by products associated
--   with each supplier.

SELECT
    s.supplier_id,
    s.country,
    COUNT(DISTINCT p.product_id) AS total_products,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COALESCE(SUM(oi.qty), 0) AS units_sold,
    ROUND(
        COALESCE(SUM(oi.qty * oi.price), 0),
        2
    ) AS gross_sales
FROM suppliers s
LEFT JOIN products p
    ON s.supplier_id = p.supplier_id
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    s.supplier_id,
    s.country
ORDER BY gross_sales DESC;


--   ============================================================
--   4.15 SUPPLIER COUNTRY SALES DISTRIBUTION
--   Aggregate supplier-linked product sales at country level.

SELECT
    s.country,
    COUNT(DISTINCT s.supplier_id) AS total_suppliers,
    COUNT(DISTINCT p.product_id) AS total_products,
    COALESCE(SUM(oi.qty), 0) AS units_sold,
    ROUND(
        COALESCE(SUM(oi.qty * oi.price), 0),
        2
    ) AS gross_sales
FROM suppliers s
LEFT JOIN products p
    ON s.supplier_id = p.supplier_id
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY s.country
ORDER BY gross_sales DESC;


--   ============================================================
--   4.16 SUPPLIER COUNTRY SALES CONTRIBUTION
--   Calculate percentage of gross sales associated with
--   suppliers from each country.

WITH country_sales AS
(
    SELECT
        s.country,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM suppliers s
    JOIN products p
        ON s.supplier_id = p.supplier_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY s.country
)
SELECT
    country,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (),
        2
    ) AS sales_contribution_pct
FROM country_sales
ORDER BY gross_sales DESC;


--   ============================================================
--   PART 5: PROMOTION & DISCOUNT EDA
--   ============================================================


--   ============================================================
--   5.1 PROMOTION OVERVIEW
--   Understand number and range of available promotions.

SELECT
    COUNT(*) AS total_promotions,
    ROUND(MIN(discount), 2) AS minimum_discount,
    ROUND(MAX(discount), 2) AS maximum_discount,
    ROUND(AVG(discount), 2) AS average_discount
FROM promotions;


--   ============================================================
--   5.2 DISCOUNT DISTRIBUTION
--   Examine the available discount values.

SELECT
    discount,
    COUNT(*) AS promotion_count
FROM promotions
GROUP BY discount
ORDER BY discount;


--   ============================================================
--   5.3 PROMOTION USAGE OVERVIEW
--   Compare promoted and non-promoted order counts.

SELECT
    CASE
        WHEN promotion_id IS NULL
            THEN 'No Promotion'
        ELSE 'Promotion'
    END AS promotion_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage
FROM orders
GROUP BY
    CASE
        WHEN promotion_id IS NULL
            THEN 'No Promotion'
        ELSE 'Promotion'
    END
ORDER BY total_orders DESC;


--   ============================================================
--   5.4 NUMBER OF TIMES EACH PROMOTION WAS USED
--   LEFT JOIN retains promotions that may never have been used.

SELECT
    p.promotion_id,
    p.discount,
    COUNT(o.order_id) AS orders_using_promotion
FROM promotions p
LEFT JOIN orders o
    ON p.promotion_id = o.promotion_id
GROUP BY
    p.promotion_id,
    p.discount
ORDER BY orders_using_promotion DESC;


--   ============================================================
--   5.5 UNUSED PROMOTIONS
--   Identify promotions never referenced by an order.

SELECT
    COUNT(*) AS unused_promotions
FROM promotions p
LEFT JOIN orders o
    ON p.promotion_id = o.promotion_id
WHERE o.order_id IS NULL;


--   ============================================================
--   5.6 PROMOTED VS NON-PROMOTED ORDER PROFILE
--   Compare orders, units and gross transaction value.
--   This is descriptive EDA only.
--   It does NOT prove that promotions caused differences.

SELECT
    CASE
        WHEN o.promotion_id IS NULL
            THEN 'No Promotion'
        ELSE 'Promotion'
    END AS promotion_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS units_sold,
    ROUND(
        SUM(oi.qty * oi.price),
        2
    ) AS gross_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    CASE
        WHEN o.promotion_id IS NULL
            THEN 'No Promotion'
        ELSE 'Promotion'
    END
ORDER BY gross_sales DESC;


--   ============================================================
--   5.7 PROMOTED VS NON-PROMOTED AVERAGE ORDER VALUE
--   First calculate each order's gross value to avoid
--   averaging order-item rows instead of orders.

WITH order_values AS
(
    SELECT
        o.order_id,
        o.promotion_id,
        SUM(oi.qty) AS units,
        SUM(oi.qty * oi.price) AS gross_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.promotion_id
)
SELECT
    CASE
        WHEN promotion_id IS NULL
            THEN 'No Promotion'
        ELSE 'Promotion'
    END AS promotion_status,
    COUNT(*) AS total_orders,
    ROUND(
        AVG(units),
        2
    ) AS avg_units_per_order,
    ROUND(
        AVG(gross_order_value),
        2
    ) AS avg_order_value
FROM order_values
GROUP BY
    CASE
        WHEN promotion_id IS NULL
            THEN 'No Promotion'
        ELSE 'Promotion'
    END
ORDER BY avg_order_value DESC;


--   ============================================================
--   5.8 SALES BY INDIVIDUAL PROMOTION
--   Explore transaction activity associated with each promotion.

SELECT
    p.promotion_id,
    p.discount,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(oi.qty), 0) AS units_sold,
    ROUND(
        COALESCE(SUM(oi.qty * oi.price), 0),
        2
    ) AS gross_sales
FROM promotions p
LEFT JOIN orders o
    ON p.promotion_id = o.promotion_id
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    p.promotion_id,
    p.discount
ORDER BY gross_sales DESC;


--   ============================================================
--   5.9 AVERAGE ORDER VALUE BY PROMOTION

WITH order_values AS
(
    SELECT
        o.order_id,
        o.promotion_id,
        SUM(oi.qty * oi.price) AS gross_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.promotion_id IS NOT NULL
    GROUP BY
        o.order_id,
        o.promotion_id
)
SELECT
    p.promotion_id,
    p.discount,
    COUNT(ov.order_id) AS total_orders,
    ROUND(
        AVG(ov.gross_order_value),
        2
    ) AS avg_order_value
FROM promotions p
LEFT JOIN order_values ov
    ON p.promotion_id = ov.promotion_id
GROUP BY
    p.promotion_id,
    p.discount
ORDER BY avg_order_value DESC;


--   ============================================================
--   5.10 SALES BY DISCOUNT VALUE
--   Multiple promotion IDs can potentially share the same
--   discount, so this aggregates them by discount value.

SELECT
    p.discount,
    COUNT(DISTINCT p.promotion_id) AS total_promotions,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(oi.qty), 0) AS units_sold,
    ROUND(
        COALESCE(SUM(oi.qty * oi.price), 0),
        2
    ) AS gross_sales
FROM promotions p
LEFT JOIN orders o
    ON p.promotion_id = o.promotion_id
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY p.discount
ORDER BY p.discount;


--   ============================================================
--   5.11 AVERAGE ORDER VALUE BY DISCOUNT

WITH order_values AS
(
    SELECT
        o.order_id,
        o.promotion_id,
        SUM(oi.qty * oi.price) AS gross_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.promotion_id IS NOT NULL
    GROUP BY
        o.order_id,
        o.promotion_id
)
SELECT
    p.discount,
    COUNT(ov.order_id) AS total_orders,
    ROUND(
        AVG(ov.gross_order_value),
        2
    ) AS avg_order_value
FROM promotions p
LEFT JOIN order_values ov
    ON p.promotion_id = ov.promotion_id
GROUP BY p.discount
ORDER BY p.discount;


--   ============================================================
--   5.12 PROMOTION USAGE BY YEAR
--   Explore whether promotion usage changes over time.

SELECT
    YEAR(order_date) AS order_year,
    SUM(
        CASE
            WHEN promotion_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS promoted_orders,
    SUM(
        CASE
            WHEN promotion_id IS NULL THEN 1
            ELSE 0
        END
    ) AS non_promoted_orders,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN promotion_id IS NOT NULL THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS promotion_usage_pct
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;


--   ============================================================
--   5.13 MONTHLY PROMOTION USAGE TREND

SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN promotion_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS promoted_orders,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN promotion_id IS NOT NULL THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS promotion_usage_pct
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;


--   ============================================================
--   5.14 PROMOTION SALES CONTRIBUTION
--   Explore the share of gross sales associated with
--   promoted vs non-promoted orders.

WITH promotion_sales AS
(
    SELECT
        CASE
            WHEN o.promotion_id IS NULL
                THEN 'No Promotion'
            ELSE 'Promotion'
        END AS promotion_status,
        SUM(oi.qty * oi.price) AS gross_sales
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
    ROUND(
        gross_sales,
        2
    ) AS gross_sales,
    ROUND(
        gross_sales * 100.0 /
        SUM(gross_sales) OVER (),
        2
    ) AS sales_contribution_pct
FROM promotion_sales
ORDER BY gross_sales DESC;


--   ============================================================
--   5.15 DISCOUNT AND ORDER VALUE EXPLORATORY SUMMARY
--   IMPORTANT: This shows association only.

WITH order_values AS
(
    SELECT
        o.order_id,
        o.promotion_id,
        SUM(oi.qty) AS units,
        SUM(oi.qty * oi.price) AS gross_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.promotion_id IS NOT NULL
    GROUP BY
        o.order_id,
        o.promotion_id
)
SELECT
    p.discount,
    COUNT(ov.order_id) AS total_orders,
    ROUND(
        AVG(ov.units),
        2
    ) AS avg_units_per_order,
    ROUND(
        AVG(ov.gross_order_value),
        2
    ) AS avg_order_value
FROM promotions p
LEFT JOIN order_values ov
    ON p.promotion_id = ov.promotion_id
GROUP BY p.discount
ORDER BY p.discount;


--   ============================================================
--   PART 6: PAYMENTS, SHIPMENTS & RETURNS EDA
--   ============================================================


--   ============================================================
--   6.1 PAYMENT AMOUNT DISTRIBUTION
--   Basic descriptive statistics for payment amounts.

SELECT
    COUNT(*) AS total_payments,
    ROUND(SUM(amount), 2) AS total_payment_amount,
    ROUND(AVG(amount), 2) AS avg_payment_amount,
    ROUND(MIN(amount), 2) AS minimum_payment_amount,
    ROUND(MAX(amount), 2) AS maximum_payment_amount
FROM payments;


--   ============================================================
--   6.2 PAYMENTS PER ORDER
--   Explore whether orders have one or multiple payment records.

WITH payment_counts AS
(
    SELECT
        order_id,
        COUNT(*) AS payment_count,
        SUM(amount) AS total_payment_amount
    FROM payments
    GROUP BY order_id
)
SELECT
    COUNT(*) AS orders_with_payments,
    ROUND(
        AVG(payment_count),
        2
    ) AS avg_payments_per_order,
    MIN(payment_count) AS min_payments_per_order,
    MAX(payment_count) AS max_payments_per_order,
    ROUND(
        AVG(total_payment_amount),
        2
    ) AS avg_total_payment_per_order
FROM payment_counts;


--   ============================================================
--   6.3 PAYMENT COUNT DISTRIBUTION
--   Shows how many orders have 1, 2, 3... payment records.

WITH payment_counts AS
(
    SELECT
        order_id,
        COUNT(*) AS payment_count
    FROM payments
    GROUP BY order_id
)
SELECT
    payment_count,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage
FROM payment_counts
GROUP BY payment_count
ORDER BY payment_count;


--   ============================================================
--   6.4 ORDER VALUE VS PAYMENT AMOUNT
--   Compare gross transaction value with recorded payments.
--   IMPORTANT:
--  	Differences are explored, not automatically treated
-- 		as errors because promotions/other dataset logic may
-- 		influence recorded payment amounts.

WITH order_values AS
(
    SELECT
        order_id,
        SUM(qty * price) AS gross_order_value
    FROM order_items
    GROUP BY order_id
),
payment_values AS
(
    SELECT
        order_id,
        SUM(amount) AS total_payment
    FROM payments
    GROUP BY order_id
)
SELECT
    COUNT(*) AS compared_orders,
    ROUND(
        AVG(ov.gross_order_value),
        2
    ) AS avg_gross_order_value,
    ROUND(
        AVG(pv.total_payment),
        2
    ) AS avg_payment,
    ROUND(
        AVG(pv.total_payment - ov.gross_order_value),
        2
    ) AS avg_difference
FROM order_values ov
JOIN payment_values pv
    ON ov.order_id = pv.order_id;


--   ============================================================
--   6.5 PAYMENT DIFFERENCE DISTRIBUTION
--   Categorize orders based on payment vs gross order value.

WITH order_values AS
(
    SELECT
        order_id,
        SUM(qty * price) AS gross_order_value
    FROM order_items
    GROUP BY order_id
),
payment_values AS
(
    SELECT
        order_id,
        SUM(amount) AS total_payment
    FROM payments
    GROUP BY order_id
),
comparison AS
(
    SELECT
        ov.order_id,
        ov.gross_order_value,
        pv.total_payment,
        pv.total_payment - ov.gross_order_value AS difference
    FROM order_values ov
    JOIN payment_values pv
        ON ov.order_id = pv.order_id
)
SELECT
    CASE
        WHEN ABS(difference) <= 0.01
            THEN 'Matched'
        WHEN difference > 0.01
            THEN 'Payment Above Gross Value'
        ELSE 'Payment Below Gross Value'
    END AS payment_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage
FROM comparison
GROUP BY
    CASE
        WHEN ABS(difference) <= 0.01
            THEN 'Matched'
        WHEN difference > 0.01
            THEN 'Payment Above Gross Value'
        ELSE 'Payment Below Gross Value'
    END
ORDER BY total_orders DESC;


--   ============================================================
--   6.6 SHIPMENT STATUS DISTRIBUTION
--   Revisit shipment status with percentage distribution.

SELECT
    status,
    COUNT(*) AS total_shipments,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS shipment_percentage
FROM shipments
GROUP BY status
ORDER BY total_shipments DESC;


--   ============================================================
--   6.7 SHIPMENT STATUS BY YEAR
--   Explore fulfillment-status patterns over time.

SELECT
    YEAR(o.order_date) AS order_year,
    s.status,
    COUNT(*) AS total_shipments
FROM shipments s
JOIN orders o
    ON s.order_id = o.order_id
GROUP BY
    YEAR(o.order_date),
    s.status
ORDER BY
    order_year,
    total_shipments DESC;


--   ============================================================
--   6.8 SHIPMENT STATUS PERCENTAGE BY YEAR

WITH yearly_shipments AS
(
    SELECT
        YEAR(o.order_date) AS order_year,
        s.status,
        COUNT(*) AS shipment_count
    FROM shipments s
    JOIN orders o
        ON s.order_id = o.order_id
    GROUP BY
        YEAR(o.order_date),
        s.status
)
SELECT
    order_year,
    status,
    shipment_count,
    ROUND(
        shipment_count * 100.0 /
        SUM(shipment_count) OVER (
            PARTITION BY order_year
        ),
        2
    ) AS yearly_status_pct
FROM yearly_shipments
ORDER BY
    order_year,
    shipment_count DESC;


--   ============================================================
--   6.9 SHIPMENT STATUS BY STORE
--   Explore shipment outcomes across branches.

SELECT
    o.store_id,
    s.status,
    COUNT(*) AS total_shipments
FROM shipments s
JOIN orders o
    ON s.order_id = o.order_id
GROUP BY
    o.store_id,
    s.status
ORDER BY
    o.store_id,
    total_shipments DESC;


--   ============================================================
--   6.10 RETURNS OVERVIEW
--   Remember: Multiple return records may legitimately reference 
--   the same order_item_id.

SELECT
    COUNT(*) AS total_return_records,
    COUNT(DISTINCT order_item_id)
        AS distinct_returned_order_items,
    ROUND(
        SUM(refund),
        2
    ) AS total_refund_amount,
    ROUND(
        AVG(refund),
        2
    ) AS avg_refund_amount,
    ROUND(
        MIN(refund),
        2
    ) AS minimum_refund,
    ROUND(
        MAX(refund),
        2
    ) AS maximum_refund
FROM returns;


--   ============================================================
--   6.11 RETURN RECORDS PER ORDER ITEM
--   Explore how many return records are associated with
--   each returned order item.

WITH return_counts AS
(
    SELECT
        order_item_id,
        COUNT(*) AS return_count
    FROM returns
    GROUP BY order_item_id
)
SELECT
    return_count,
    COUNT(*) AS order_items,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_returned_items
FROM return_counts
GROUP BY return_count
ORDER BY return_count;


--   ============================================================
--   6.12 OVERALL ORDER-ITEM RETURN RATE
--   Return rate is based on DISTINCT returned order_item_id,
--   not number of return records.

SELECT
    COUNT(*) AS total_order_items,
    (
        SELECT COUNT(DISTINCT order_item_id)
        FROM returns
    ) AS returned_order_items,
    ROUND(
        (
            SELECT COUNT(DISTINCT order_item_id)
            FROM returns
        ) * 100.0 / COUNT(*),
        2
    ) AS order_item_return_rate_pct
FROM order_items;


--   ============================================================
--   6.13 RETURNS BY PRODUCT
--   Explore product-level return frequency and refunds.

SELECT
    p.product_id,
    COUNT(DISTINCT r.order_item_id)
        AS returned_order_items,
    COUNT(r.return_id)
        AS return_records,
    ROUND(
        COALESCE(SUM(r.refund), 0),
        2
    ) AS total_refund_amount
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
LEFT JOIN returns r
    ON oi.order_item_id = r.order_item_id
GROUP BY p.product_id
ORDER BY total_refund_amount DESC;


--   ============================================================
--   6.14 PRODUCT RETURN RATE
--   Compare distinct returned order items with 
--   total order-item records for each product.

SELECT
    p.product_id,
    COUNT(DISTINCT oi.order_item_id)
        AS total_order_items,
    COUNT(DISTINCT r.order_item_id)
        AS returned_order_items,
    ROUND(
        COUNT(DISTINCT r.order_item_id) * 100.0 /
        NULLIF(
            COUNT(DISTINCT oi.order_item_id),
            0
        ),
        2
    ) AS return_rate_pct
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
LEFT JOIN returns r
    ON oi.order_item_id = r.order_item_id
GROUP BY p.product_id
ORDER BY return_rate_pct DESC;


--   ============================================================
--   6.15 RETURNS BY CATEGORY

SELECT
    c.category_id,
    c.category_name,
    COUNT(DISTINCT oi.order_item_id)
        AS total_order_items,
    COUNT(DISTINCT r.order_item_id)
        AS returned_order_items,
    ROUND(
        COUNT(DISTINCT r.order_item_id) * 100.0 /
        NULLIF(
            COUNT(DISTINCT oi.order_item_id),
            0
        ),
        2
    ) AS return_rate_pct,
    ROUND(
        COALESCE(SUM(r.refund), 0),
        2
    ) AS total_refund_amount
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
ORDER BY return_rate_pct DESC;


--   ============================================================
--   6.16 RETURNS BY STORE
--   Explore return activity associated with each branch.

SELECT
    s.store_id,
    s.city,
    COUNT(DISTINCT oi.order_item_id)
        AS total_order_items,
    COUNT(DISTINCT r.order_item_id)
        AS returned_order_items,
    ROUND(
        COUNT(DISTINCT r.order_item_id) * 100.0 /
        NULLIF(
            COUNT(DISTINCT oi.order_item_id),
            0
        ),
        2
    ) AS return_rate_pct,
    ROUND(
        COALESCE(SUM(r.refund), 0),
        2
    ) AS total_refund_amount
FROM stores s
JOIN orders o
    ON s.store_id = o.store_id
JOIN order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN returns r
    ON oi.order_item_id = r.order_item_id
GROUP BY
    s.store_id,
    s.city
ORDER BY return_rate_pct DESC;


--   ============================================================
--   6.17 REFUND AMOUNT VS ORIGINAL ORDER-ITEM VALUE
--   Aggregate multiple refund records first.
--   Compare: total refund vs qty * transaction price

WITH item_refunds AS
(
    SELECT
        order_item_id,
        SUM(refund) AS total_refund
    FROM returns
    GROUP BY order_item_id
)
SELECT
    COUNT(*) AS returned_items,
    ROUND(
        AVG(oi.qty * oi.price),
        2
    ) AS avg_original_item_value,
    ROUND(
        AVG(ir.total_refund),
        2
    ) AS avg_total_refund,
    ROUND(
        AVG(
            ir.total_refund /
            NULLIF(oi.qty * oi.price, 0)
            * 100
        ),
        2
    ) AS avg_refund_to_value_pct
FROM item_refunds ir
JOIN order_items oi
    ON ir.order_item_id = oi.order_item_id;


--   ============================================================
--   6.18 REFUND-TO-VALUE DISTRIBUTION

WITH item_refunds AS
(
    SELECT
        order_item_id,
        SUM(refund) AS total_refund
    FROM returns
    GROUP BY order_item_id
),
refund_profile AS
(
    SELECT
        ir.order_item_id,
        ir.total_refund,
        oi.qty * oi.price AS original_item_value,
        ir.total_refund /
        NULLIF(oi.qty * oi.price, 0)
        * 100 AS refund_pct
    FROM item_refunds ir
    JOIN order_items oi
        ON ir.order_item_id = oi.order_item_id
)
SELECT
    CASE
        WHEN refund_pct < 100
            THEN 'Below Item Value'
        WHEN refund_pct BETWEEN 99.99 AND 100.01
            THEN 'Approximately Full Value'
        ELSE 'Above Item Value'
    END AS refund_value_status,
    COUNT(*) AS returned_items,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS returned_item_percentage
FROM refund_profile
GROUP BY
    CASE
        WHEN refund_pct < 100
            THEN 'Below Item Value'
        WHEN refund_pct BETWEEN 99.99 AND 100.01
            THEN 'Approximately Full Value'
        ELSE 'Above Item Value'
    END
ORDER BY returned_items DESC;


--   ============================================================
--   6.19 RETURNS BY SHIPMENT STATUS
--   Explore whether returned items are associated differently
--   with DELIVERED, LATE or SHIPPED orders.
--   This is association only and does not establish causation.

SELECT
    s.status,
    COUNT(DISTINCT oi.order_item_id)
        AS total_order_items,
    COUNT(DISTINCT r.order_item_id)
        AS returned_order_items,
    ROUND(
        COUNT(DISTINCT r.order_item_id) * 100.0 /
        NULLIF(
            COUNT(DISTINCT oi.order_item_id),
            0
        ),
        2
    ) AS return_rate_pct,
    ROUND(
        COALESCE(SUM(r.refund), 0),
        2
    ) AS total_refund_amount
FROM shipments s
JOIN orders o
    ON s.order_id = o.order_id
JOIN order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN returns r
    ON oi.order_item_id = r.order_item_id
GROUP BY s.status
ORDER BY return_rate_pct DESC;


--   ============================================================
--   6.20 MONTHLY RETURN TREND
--   Returns table has no return-date field.
--   Therefore this analysis uses the associated ORDER DATE,
--   not the actual date the return occurred.
--   This must not be interpreted as true monthly return timing.

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    COUNT(DISTINCT r.order_item_id)
        AS returned_order_items,
    ROUND(
        SUM(r.refund),
        2
    ) AS refund_amount
FROM returns r
JOIN order_items oi
    ON r.order_item_id = oi.order_item_id
JOIN orders o
    ON oi.order_id = o.order_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY order_month;


--   ========================================================================
--   6.21 MONTHLY ORDER-ITEM RETURN RATE
--   Again, the month represents ORDER MONTH rather than actual return month.

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    COUNT(DISTINCT oi.order_item_id)
        AS total_order_items,
    COUNT(DISTINCT r.order_item_id)
        AS returned_order_items,
    ROUND(
        COUNT(DISTINCT r.order_item_id) * 100.0 /
        NULLIF(
            COUNT(DISTINCT oi.order_item_id),
            0
        ),
        2
    ) AS return_rate_pct
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN returns r
    ON oi.order_item_id = r.order_item_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY order_month;


--   ============================================================
--   6.22 FINAL OPERATIONAL EDA SUMMARY
--   High-level summary of payments, shipments and returns.

SELECT
    (SELECT COUNT(*) FROM payments)
        AS payment_records,
    ROUND(
        (SELECT SUM(amount) FROM payments),
        2
    ) AS total_payments,
    (SELECT COUNT(*) FROM shipments)
        AS shipment_records,
    (
        SELECT COUNT(*)
        FROM shipments
        WHERE status = 'LATE'
    ) AS late_shipments,
    (SELECT COUNT(*) FROM returns)
        AS return_records,
    (
        SELECT COUNT(DISTINCT order_item_id)
        FROM returns
    ) AS distinct_returned_items,
    ROUND(
        (SELECT SUM(refund) FROM returns),
        2
    ) AS total_refunds;




/* ======================= END OF FILE ======================== */