
--   =================================================================
--   PROJECT 2: MULTI-BRANCH RETAIL PERFORMANCE & REVENUE INTELLIGENCE
--   DATABASE: MySQL 8.0
--   FILE: 01_Create_Tables.sql
--   PURPOSE:
--   	Create 12 schemas needed for analysis
--   =================================================================

CREATE DATABASE retail_dw;
USE retail_dw;

-- 1. Categories
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100)
);

-- 2. Customers
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    city VARCHAR(100),
    signup_date DATE
);

-- 3. Stores
CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    city VARCHAR(100)
);

-- 4. Suppliers
CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    country VARCHAR(100)
);

-- 5. Promotions
CREATE TABLE promotions (
    promotion_id INT PRIMARY KEY,
    discount DECIMAL(10,2)
);

-- 6. Products
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    category_id INT,
    supplier_id INT,
    price DECIMAL(10,2),

    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id),

    CONSTRAINT fk_products_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
);

-- 7. Employees
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    store_id INT,
    salary DECIMAL(10,2),

    CONSTRAINT fk_employees_store
        FOREIGN KEY (store_id)
        REFERENCES stores(store_id)
);

-- 8. Orders
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    store_id INT,
    order_date DATE,
    promotion_id INT,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_orders_store
        FOREIGN KEY (store_id)
        REFERENCES stores(store_id),

    CONSTRAINT fk_orders_promotion
        FOREIGN KEY (promotion_id)
        REFERENCES promotions(promotion_id)
);

-- 9. Order Items
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    qty INT,
    price DECIMAL(10,2),

    CONSTRAINT fk_orderitems_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT fk_orderitems_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

-- 10. Payments
CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
    amount DECIMAL(12,2),

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);

-- 11. Shipments
CREATE TABLE shipments (
    shipment_id INT PRIMARY KEY,
    order_id INT,
    status VARCHAR(50),

    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);

-- 12. Returns
CREATE TABLE returns (
    return_id INT PRIMARY KEY,
    order_item_id INT,
    refund DECIMAL(12,2),

    CONSTRAINT fk_returns_orderitem
        FOREIGN KEY (order_item_id)
        REFERENCES order_items(order_item_id)
);

SHOW TABLES;

-- Number of Tables in this Database
SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'retail_dw';




/* ======================= END OF FILE ======================== */