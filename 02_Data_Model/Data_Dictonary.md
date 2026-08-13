# Data Dictionary

## Multi-Branch Retail Performance & Revenue Intelligence

This data dictionary documents the relational database structure used in the Multi-Branch Retail Performance & Revenue Intelligence project.

The MySQL database contains 12 core tables covering customers, stores, employees, products, categories, suppliers, promotions, orders, order items, payments, shipments, and returns.

---

# 1. Table Definitions

## 1.1 categories

**Grain:** One row per product category.

| Column | Data Type | Key | Description |
|---|---|---|---|
| category_id | INT | Primary Key | Unique identifier for each product category |
| category_name | VARCHAR(100) | — | Name of the product category |

---

## 1.2 customers

**Grain:** One row per customer.

| Column | Data Type | Key | Description |
|---|---|---|---|
| customer_id | INT | Primary Key | Unique identifier for each customer |
| city | VARCHAR(100) | — | Customer city |
| signup_date | DATE | — | Recorded customer signup date |

---

## 1.3 stores

**Grain:** One row per retail store.

| Column | Data Type | Key | Description |
|---|---|---|---|
| store_id | INT | Primary Key | Unique identifier for each retail store |
| city | VARCHAR(100) | — | City in which the store is located |

---

## 1.4 suppliers

**Grain:** One row per supplier.

| Column | Data Type | Key | Description |
|---|---|---|---|
| supplier_id | INT | Primary Key | Unique identifier for each supplier |
| country | VARCHAR(100) | — | Supplier country |

---

## 1.5 promotions

**Grain:** One row per promotion.

| Column | Data Type | Key | Description |
|---|---|---|---|
| promotion_id | INT | Primary Key | Unique identifier for each promotion |
| discount | DECIMAL(10,2) | — | Recorded promotion discount value |

---

## 1.6 products

**Grain:** One row per product.

| Column | Data Type | Key | Description |
|---|---|---|---|
| product_id | INT | Primary Key | Unique identifier for each product |
| category_id | INT | Foreign Key | Category associated with the product |
| supplier_id | INT | Foreign Key | Supplier associated with the product |
| price | DECIMAL(10,2) | — | Product/master price |

**Relationships**

- `category_id` → `categories.category_id`
- `supplier_id` → `suppliers.supplier_id`

---

## 1.7 employees

**Grain:** One row per employee.

| Column | Data Type | Key | Description |
|---|---|---|---|
| employee_id | INT | Primary Key | Unique identifier for each employee |
| store_id | INT | Foreign Key | Store associated with the employee |
| salary | DECIMAL(10,2) | — | Recorded employee salary |

**Relationship**

- `store_id` → `stores.store_id`

---

## 1.8 orders

**Grain:** One row per order.

| Column | Data Type | Key | Description |
|---|---|---|---|
| order_id | INT | Primary Key | Unique identifier for each order |
| customer_id | INT | Foreign Key | Customer associated with the order |
| store_id | INT | Foreign Key | Store associated with the order |
| order_date | DATE | — | Date on which the order was recorded |
| promotion_id | INT | Foreign Key | Promotion associated with the order |

**Relationships**

- `customer_id` → `customers.customer_id`
- `store_id` → `stores.store_id`
- `promotion_id` → `promotions.promotion_id`

---

## 1.9 order_items

**Grain:** One row per order line item.

| Column | Data Type | Key | Description |
|---|---|---|---|
| order_item_id | INT | Primary Key | Unique identifier for each order line item |
| order_id | INT | Foreign Key | Order containing the line item |
| product_id | INT | Foreign Key | Product purchased |
| qty | INT | — | Quantity purchased |
| price | DECIMAL(10,2) | — | Transaction-level selling price |

**Relationships**

- `order_id` → `orders.order_id`
- `product_id` → `products.product_id`

---

## 1.10 payments

**Grain:** One row per payment record.

| Column | Data Type | Key | Description |
|---|---|---|---|
| payment_id | INT | Primary Key | Unique identifier for each payment record |
| order_id | INT | Foreign Key | Order associated with the payment |
| amount | DECIMAL(12,2) | — | Recorded payment amount |

**Relationship**

- `order_id` → `orders.order_id`

---

## 1.11 shipments

**Grain:** One row per shipment record.

| Column | Data Type | Key | Description |
|---|---|---|---|
| shipment_id | INT | Primary Key | Unique identifier for each shipment |
| order_id | INT | Foreign Key | Order associated with the shipment |
| status | VARCHAR(50) | — | Recorded shipment status |

**Relationship**

- `order_id` → `orders.order_id`

---

## 1.12 returns

**Grain:** One row per return/refund record.

| Column | Data Type | Key | Description |
|---|---|---|---|
| return_id | INT | Primary Key | Unique identifier for each return/refund record |
| order_item_id | INT | Foreign Key | Order item associated with the return |
| refund | DECIMAL(12,2) | — | Recorded refund amount |

**Relationship**

- `order_item_id` → `order_items.order_item_id`

---

# 2. Relationship Summary

| Parent Table | Child Table | Foreign Key | Relationship |
|---|---|---|---|
| categories | products | category_id | One category can contain many products |
| suppliers | products | supplier_id | One supplier can be associated with many products |
| stores | employees | store_id | One store can have many employees |
| customers | orders | customer_id | One customer can place many orders |
| stores | orders | store_id | One store can be associated with many orders |
| promotions | orders | promotion_id | One promotion can be associated with many orders |
| orders | order_items | order_id | One order can contain many order items |
| products | order_items | product_id | One product can appear in many order items |
| orders | payments | order_id | One order can be associated with payment records |
| orders | shipments | order_id | One order can be associated with shipment records |
| order_items | returns | order_item_id | One order item can be associated with return records |

---

# 3. Table Grain Summary

| Table | Grain |
|---|---|
| categories | One row per product category |
| customers | One row per customer |
| stores | One row per retail store |
| suppliers | One row per supplier |
| promotions | One row per promotion |
| products | One row per product |
| employees | One row per employee |
| orders | One row per order |
| order_items | One row per order line item |
| payments | One row per payment record |
| shipments | One row per shipment record |
| returns | One row per return/refund record |

---

# 4. Important Data Model Notes

## 4.1 Transaction Revenue

Historical gross sales are calculated using the transaction-level fields:

`order_items.qty × order_items.price`

`order_items.price` is treated as the transaction-level selling price, while `products.price` represents the product/master price.

The master product price is therefore not substituted for the historical transaction price when calculating sales.

---

## 4.2 Profitability Limitation

The available dataset does not contain an explicit product cost or Cost of Goods Sold (COGS) field.

Therefore, true gross profit, gross margin, net profit, and accounting profitability cannot be calculated reliably.

The project consequently focuses on:

- Gross sales/revenue performance
- Store and branch performance
- Product and category performance
- Customer purchasing behavior
- Refund exposure
- Returns
- Promotions
- Shipment performance
- Other operational and revenue-related indicators

Revenue is not presented as profit.

---

## 4.3 Customer Signup Date

The data-quality audit identified transactions where `order_date` occurs before the associated customer's `signup_date`.

Because of this temporal inconsistency, `signup_date` is not used for:

- Customer tenure calculations
- Acquisition-cohort analysis
- Pre/post-signup purchasing analysis

The affected transactions are retained rather than deleted because the inconsistency relates to the customer signup field and does not by itself establish that the transaction is invalid.

---

## 4.4 Returns

The `returns` table does not contain a return-date field.

Therefore, the dataset cannot reliably support:

- Actual return-month trends
- Time-to-return calculations
- Return timing analysis

Any time-based association involving returns must refer to the original order period rather than the actual date on which the return occurred.

Multiple return records can also reference the same `order_item_id`.

Where analysis requires the number of returned order items, distinct `order_item_id` values should therefore be used instead of treating every return record as a separate returned item.

---

## 4.5 Promotions

Orders are linked to promotions through `promotion_id`, while the `promotions` table provides the recorded discount value.

However, the available schema does not establish whether `order_items.price` represents a pre-discount or post-discount transaction price.

The promotion discount should therefore not automatically be subtracted again from the transaction price.

Promotion-related comparisons are interpreted as descriptive associations and not as evidence that a promotion caused a change in sales or customer behavior.

---

## 4.6 Payments

The `payments.amount` field records payment value associated with an order.

Differences between recorded payment amount and calculated order value should be investigated rather than automatically treated as erroneous because the available schema may not fully represent all payment, pricing, or promotion logic.

---

# 5. Core Transaction Flow

The primary analytical path through the relational model is:

`customers → orders → order_items → products`

Additional dimensions and operational tables extend this structure:

- `stores → orders`
- `stores → employees`
- `promotions → orders`
- `categories → products`
- `suppliers → products`
- `orders → payments`
- `orders → shipments`
- `order_items → returns`

This structure supports analysis across customer, store, product, category, supplier, promotion, payment, shipment, return, and employee dimensions while preserving the grain of the underlying transactional tables.

---

# End of Data Dictionary