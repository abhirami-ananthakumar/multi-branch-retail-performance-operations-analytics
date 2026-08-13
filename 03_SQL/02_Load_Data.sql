
-- =================================================================
-- PROJECT 2: MULTI-BRANCH RETAIL PERFORMANCE & REVENUE INTELLIGENCE
-- DATABASE: MySQL 8.0
-- FILE: 02_Load_Data.sql
-- PURPOSE:
--    Load raw CSV datasets into the retail_dw database
--    and perform basic post-load validation.
--   ===============================================================

-- Select Database
USE retail_dw;

-- Enable Local File Loading
SET GLOBAL local_infile = ON;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

-- 1. Load categories
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/categories.csv'
INTO TABLE categories
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(category_id, category_name);

-- 2. Load customers
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, city, signup_date);

-- 3. Load stores
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/stores.csv'
INTO TABLE stores
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(store_id, city, store_type);

-- 4. Load suppliers
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/suppliers.csv'
INTO TABLE suppliers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(supplier_id, country);

-- 5. Load promotions
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/promotions.csv'
INTO TABLE promotions
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(promotion_id, discount);

-- 6. Load products
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, category_id, supplier_id, price);

-- 7. Load employees
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/employees.csv'
INTO TABLE employees
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(employee_id, store_id, role, salary);

-- 8. Load orders
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, store_id, order_date, channel);

-- 9. Load order_items
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_item_id, order_id, product_id, quantity, unit_price, discount);

-- 10. Load payments
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/payments.csv'
INTO TABLE payments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(payment_id, order_id, payment_method, amount);

-- 11. Load shipments
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/shipments.csv'
INTO TABLE shipments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(shipment_id, order_id, shipment_status);

-- 12. Load returns
LOAD DATA LOCAL INFILE
'C:/Users/abhir/OneDrive/Documents/Multi-Branch_Retail_Performance_Operations_Analysis/01_Dataset/returns.csv'
INTO TABLE returns
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(return_id, order_item_id, refund);

-- Final Load validation
-- Check number of records successfully loaded into each table.
SELECT 'categories' AS table_name, COUNT(*) AS row_count
FROM categories
UNION ALL
SELECT 'customers', COUNT(*)
FROM customers
UNION ALL
SELECT 'stores', COUNT(*)
FROM stores
UNION ALL
SELECT 'suppliers', COUNT(*)
FROM suppliers
UNION ALL
SELECT 'promotions', COUNT(*)
FROM promotions
UNION ALL
SELECT 'products', COUNT(*)
FROM products
UNION ALL
SELECT 'employees', COUNT(*)
FROM employees
UNION ALL
SELECT 'orders', COUNT(*)
FROM orders
UNION ALL
SELECT 'order_items', COUNT(*)
FROM order_items
UNION ALL
SELECT 'payments', COUNT(*)
FROM payments
UNION ALL
SELECT 'shipments', COUNT(*)
FROM shipments
UNION ALL
SELECT 'returns', COUNT(*)
FROM returns;

-- Check total number of rows accross 12 tables
SELECT
      (SELECT COUNT(*) FROM categories)
    + (SELECT COUNT(*) FROM customers)
    + (SELECT COUNT(*) FROM employees)
    + (SELECT COUNT(*) FROM order_items)
    + (SELECT COUNT(*) FROM orders)
    + (SELECT COUNT(*) FROM payments)
    + (SELECT COUNT(*) FROM products)
    + (SELECT COUNT(*) FROM promotions)
    + (SELECT COUNT(*) FROM returns)
    + (SELECT COUNT(*) FROM shipments)
    + (SELECT COUNT(*) FROM stores)
    + (SELECT COUNT(*) FROM suppliers)
    AS total_database_rows;

/* ============================================================
   EXPECTED MAJOR TABLE COUNTS

   categories	 = 30
   customers     = 50,000
   stores		 = 100
   supplies		 = 200
   promotions	 = 50
   products      = 10,000
   employees     = 1,000
   orders        = 300,000
   order_items   = 600,000
   payments      = 300,000
   shipments     = 300,000
   returns       = 30,000
   
   TOTAL DATABASE ROWS = 1,591,380

   NOTE:
   Detailed duplicate, refund, consistency and business-rule
   checks are intentionally deferred to 03_Data_Cleaning.sql.

   ============================================================ */




/* ======================= END OF FILE ======================== */