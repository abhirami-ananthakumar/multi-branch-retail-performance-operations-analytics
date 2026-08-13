# Multi-Branch Retail Performance & Operations Intelligence

An end-to-end retail analytics project using **Excel, MySQL, SQL, Power BI and DAX** to analyze sales, store performance, products, categories, customers, shipments, returns and refunds across four major cities in India.

The project transforms raw retail warehouse data into a validated business intelligence solution with **5 interactive Power BI dashboards**, SQL-based KPI validation, business insights and management recommendations.

---

## 📌 Project Overview

The retail business operates across four cities:

- Mumbai
- Pune
- Delhi
- Bangalore

The project analyzes approximately **1.59 million records across 12 retail warehouse tables** to provide management with a centralized view of commercial and operational performance.

The analysis covers:

- Sales performance
- Store performance
- Product and category performance
- Customer behavior
- Shipment performance
- Returns and refunds
- Business opportunities
- Operational improvement

---

## 🎯 Business Problem

The retail organization generates large volumes of transactional, customer, product, payment, shipment and return data across multiple cities.

Management needs a centralized analytical solution to:

- Measure sales, orders, AOV and growth
- Compare city and store performance
- Identify high-performing products and categories
- Understand customer purchase frequency and value
- Measure repeat-customer behavior
- Monitor shipment and late-delivery performance
- Analyze returns and refund value
- Identify revenue and operational improvement opportunities

---

## 🎯 Business Task

Analyze the four-city retail business and provide management with a comprehensive, validated view of:

- Sales and store performance
- Product and category performance
- Customer value and behavior
- Shipment and delivery performance
- Returns and refunds
- City-level differences
- Business improvement opportunities

Critical Power BI outputs were independently reconciled against SQL results before finalization.

---

## 🎯 Project Objectives

- Analyze overall retail sales performance
- Compare Mumbai, Pune, Delhi and Bangalore
- Identify leading products and categories
- Analyze customer value and purchase frequency
- Measure repeat-customer performance
- Evaluate shipment and late-delivery performance
- Analyze returns and refunds
- Build interactive Power BI dashboards
- Validate dashboard KPIs using SQL
- Generate actionable business recommendations
- Document data limitations and analytical caveats

---

# 🛠️ Technology Stack

| Tool | Purpose |
|---|---|
| Excel | Initial data inspection |
| MySQL 8.0 | Data warehouse querying, EDA, aggregation and validation |
| SQL | Joins, aggregations, distinct counts, KPI calculations and validation |
| Power BI | Data modeling, relationships, slicers and dashboards |
| DAX | Reusable measures, ratios and calculated columns |
| Google Docs | Project documentation |
| Google Slides | Project presentation |
| GitHub | Portfolio hosting and version control |

---

# 📊 Dataset

The project uses a **12-table retail data warehouse dataset** containing approximately **1,591,380 records**.

| Table | Records |
|---|---:|
| Categories | 30 |
| Customers | 50,000 |
| Employees | 1,000 |
| Order Items | 600,000 |
| Orders | 300,000 |
| Payments | 300,000 |
| Products | 10,000 |
| Promotions | 50 |
| Returns | 30,000 |
| Shipments | 300,000 |
| Stores | 100 |
| Suppliers | 200 |
| **Total** | **1,591,380** |

---

# 🔄 Analytics Workflow

| 📦 Raw Retail Data | 🔍 Data Inspection | 🗄️ MySQL / SQL Analysis | ✅ SQL KPI Validation | 📊 Power BI Data Model |
|:---:|:---:|:---:|:---:|:---:|
| ↓ | ↓ | ↓ | ↓ | ↓ |
| 🧮 DAX Measures | 📈 Interactive Dashboards | 🔄 SQL Reconciliation | 💡 Business Insights | 🎯 Management Recommendations |
---

# 📈 Power BI Dashboards

The project contains **5 interactive Power BI dashboards**, covering executive performance, stores, products and categories, customers, and operations.

---

# 1️⃣ Dashboard 1 — Executive Overview

### Purpose

Provides a high-level view of overall retail business performance across sales, orders, customers, AOV and growth.

### KPIs

| KPI | Validated Value |
|---|---:|
| Gross Sales | ~₹3.83B |
| Total Orders | 300K |
| Average Order Value | ₹12.76K |
| Total Customers | ~50K |
| YoY Sales Growth | 29.77% |

### Visuals

- Monthly Sales Trend
- Sales by Store / City
- Sales by Product Category
- Sales by Quarter

### Key Findings

- Mumbai is the strongest revenue market.
- Overall sales growth is 29.77% YoY.
- Average Order Value is approximately ₹12.76K.
- Monthly sales remain relatively stable.
- Q4 is the strongest quarter.

### Business Takeaway

The business demonstrates strong overall revenue performance, with Mumbai leading sales contribution and Q4 emerging as the strongest quarter.

---

# 2️⃣ Dashboard 2 — Store Performance

### Purpose

Compares store and city-level performance to identify leading and underperforming markets.

### KPIs

| KPI | Validated Value |
|---|---:|
| Top Performing store | Mumbai |
| Best sales Month | 2020-12 |
| Top Product Category | Cat_5 |
| Highest AOV Store | Mumbai |
| Highest Order Store | Mumbai |

### Visuals

- Orders by Store
- Monthly Sales Trend by Store
- Average Order Value by Store
- Customers by Store
- Store Performance by Year
- Category Performance by Store
- Sales Contribution by Store

### Key Findings

- Mumbai is the strongest-performing market.
- Mumbai leads in order volume and customer base.
- Mumbai has the highest AOV position in the store comparison.
- Mumbai contributes approximately **31% of total sales**.
- Pune is the second-largest contributor.
- Delhi and Bangalore show comparatively lower performance.
- Category performance differs across cities.

### Business Takeaway

Mumbai is the strongest commercial market, while the differences between cities indicate an opportunity for localized product, inventory and sales strategies.

---

# 3️⃣ Dashboard 3 — Product & Category Performance

### Purpose

Analyzes product and category performance to identify leading products, categories, sales patterns and AOV differences.

### KPIs

| KPI | Validated Value |
|---|---:|
| Top Product | 745 |
| Top Product Category | Cat_5 |
| Total Products | ~10K |
| Total Quantity | ~2M |

### Visuals

- Top 10 Categories by Sales
- Gross Sales by Year, Month and Category
- Top 10 Products by Sales
- Category Performance
- Average Order Value by Category

### Key Findings

- Product **745** is the top product.
- **Cat_5** is the leading product category.
- Approximately **10K distinct products** are represented.
- Approximately **2M units** are represented.
- Leading categories are relatively diversified.
- Category AOV varies across categories.

### Business Takeaway

Product and category performance is diversified, with Product 745 and Cat_5 leading their respective rankings. Differences in category AOV create opportunities for product-mix optimization, cross-selling and inventory planning.

---

# 4️⃣ Dashboard 4 — Customer Performance

### Purpose

Analyzes customer distribution, purchase frequency, customer value and repeat-customer behavior.

### KPIs

| KPI | Validated Value |
|---|---:|
| Total Customers | ~50K |
| Active Customers | 49,886 |
| Average Orders per Customer | 6.01 |
| Average Customer Value | ₹76.73K |
| Top Customer ID | 33455 |
| Repeat Customer Rate | 98.56% |

### Visuals

- Customers by City
- Customer Sales by City
- Top 10 Customers by Sales
- Average Orders per Customer by City
- Customer Orders Trend
- Customer Value Distribution

### Key Findings

- Mumbai has the largest customer base.
- Mumbai has the highest customer sales.
- Average purchase frequency is approximately 6 orders per customer.
- Repeat Customer Rate is **98.56%**.
- The largest customer-value segment is **₹50K–₹100K**.
- Customer **33455** is the top customer by sales.

### Business Takeaway

Customer retention is exceptionally strong. The major opportunity is to increase the value of existing customers through loyalty, cross-selling, upselling, personalization and product bundles.

---

# 5️⃣ Dashboard 5 — Operations, Returns & Shipments

### Purpose

Evaluates shipment status, late deliveries, payment trends, returns and refunds to identify operational risks.

### KPIs

| KPI | Validated Value |
|---|---:|
| Total Shipments | 300,000 |
| Late Shipments | 99,855 |
| Late Delivery Rate | 33.29% |
| Total Refunds | ₹75,962,300 |
| Returned Items | 29,251 |

### Visuals

- Shipment Status Distribution
- Late Shipments by City
- Payment Amount Trend
- Return Rate by City
- Shipment Status by City

### Key Findings

- 99,855 of 300,000 shipments are classified as late.
- The overall late-delivery rate is 33.29%.
- Mumbai has the highest absolute number of late shipments.
- Pune has the highest return rate at 5.04%.
- Refund value totals approximately ₹75.96M.
- 29,251 order items were returned.

### Business Takeaway

Delivery reliability is a major operational concern. Return reduction is another important opportunity to protect revenue and improve operational efficiency.

---

# 🔎 Dashboard Comparison

| Dashboard | Primary Focus | Main Business Question |
|---|---|---|
| Dashboard 1 | Executive Overview | How is the overall business performing? |
| Dashboard 2 | Store Performance | Which cities/stores are performing best? |
| Dashboard 3 | Product & Category | Which products and categories drive performance? |
| Dashboard 4 | Customer Performance | Who are the most valuable and loyal customers? |
| Dashboard 5 | Operations | Where are delivery and return problems occurring? |

---

# ✅ SQL-to-Power BI Validation

SQL was used as an independent validation layer for the Power BI dashboards.

The validation process followed:

```text
SQL Calculation
      ↓
Power BI Measure
      ↓
Value Comparison
      ↓
Reconciliation
      ↓
Final Dashboard

---

# 💡 Key Business Insights

The analysis identified several important commercial, customer and operational patterns across the four-city retail business.

---

## 💰 Revenue & Sales Insights

- Gross sales are approximately **₹3.83B**.
- YoY sales growth is **29.77%**.
- Mumbai is the strongest revenue market.
- Mumbai contributes approximately **31% of total sales**.
- Average Order Value is approximately **₹12.76K**.
- Q4 is the strongest quarter by gross sales.
- Sales performance varies across cities and periods.

### Business Interpretation

The business demonstrates strong overall sales performance and growth. Mumbai is the primary commercial market, while Q4 represents the strongest period. Understanding the factors behind these stronger results can help improve performance consistency across weaker markets and periods.

---

## 🏪 Store & City Insights

- Mumbai leads overall store performance.
- Mumbai has the highest order volume.
- Mumbai has the largest customer base.
- Mumbai has the strongest AOV position in the store comparison.
- Pune is the second-largest contributor.
- Delhi and Bangalore show comparatively lower performance.
- Category performance differs across cities.

### Business Interpretation

The differences between cities indicate that a single strategy may not be optimal for all markets. Management can analyze successful practices in Mumbai and Pune and identify which approaches may be transferable to Delhi and Bangalore.

---

## 📦 Product & Category Insights

- Approximately **10K distinct products** are represented.
- Approximately **2M units** are represented.
- **Product 745** is the top product.
- **Cat_5** is the top product category.
- Leading categories are relatively diversified.
- AOV differs across categories.
- Product and category performance varies across the business.

### Business Interpretation

The large product portfolio creates opportunities for better inventory allocation, product prioritization and SKU optimization. Strong performers such as Product 745 and Cat_5 should be protected while weaker products can be reviewed for optimization opportunities.

---

## 👥 Customer Insights

- The customer master contains approximately **50K customers**.
- **49,886 customers** are active.
- **49,168 customers** are repeat customers.
- **718 customers** are one-time customers.
- Repeat Customer Rate is **98.56%**.
- Average Orders per Customer is **6.01**.
- Average Customer Value is approximately **₹76.73K**.
- Customer **33455** is the top customer.
- The largest customer-value segment is **₹50K–₹100K**.
- Mumbai has the largest customer base and highest customer sales.

### Business Interpretation

Customer retention is already very strong. With a 98.56% repeat customer rate, the greater opportunity is to increase the value generated by existing customers through cross-selling, upselling, loyalty programs, personalization and product bundles.

---

## 🚚 Shipment & Operations Insights

- Total shipments are **300,000**.
- **99,855 shipments** are classified as late.
- Late Delivery Rate is **33.29%**.
- Mumbai has the highest absolute number of late shipments.
- Pune has **24,999** late shipments.
- Bangalore has **24,935** late shipments.
- Delhi has **24,505** late shipments.

### Business Interpretation

Late deliveries represent a significant operational issue. However, absolute shipment counts should not alone be used to identify the worst-performing city because shipment volumes differ. Normalized delivery rates should be used for fair city-level comparisons.

---

## 🔄 Returns & Refund Insights

- Returned items total **29,251**.
- Total refunds are approximately **₹75.96M**.
- Pune has the highest return rate at **5.04%**.
- Delhi has a return rate of **5.02%**.
- Bangalore has a return rate of **4.99%**.
- Mumbai has a return rate of **4.96%**.

### Business Interpretation

Return rates are relatively close across the four cities, but Pune has the highest observed return rate. Further analysis of return reasons, products and categories would be required to identify preventable returns.

---

## 💳 Payment Insights

Payment amount trends were analyzed as part of the operations dashboard.

The available payment data does **not** contain payment method or payment status fields.

Therefore:

- Payment-method analysis is not claimed.
- Payment-status analysis is not claimed.
- Payment-to-order-value differences should be treated as reconciliation differences requiring investigation rather than automatically classified as errors.

---

# 🎯 Management Recommendations

## Recommendation 1: Improve Delivery Reliability

Reduce the current **33.29% late-delivery rate** by:

- Investigating shipment processing delays
- Analyzing city-level operational bottlenecks
- Tracking monthly delivery performance
- Establishing delivery performance targets
- Investigating carrier and route performance when those attributes become available

---

## Recommendation 2: Increase Customer Value

Leverage the **98.56% repeat customer rate** by:

- Introducing loyalty programs
- Using personalized promotions
- Encouraging cross-selling
- Encouraging upselling
- Creating product bundles
- Moving customers toward higher-value segments

The next growth opportunity should focus on increasing customer value rather than relying only on customer acquisition.

---

## Recommendation 3: Reduce Returns

Reduce avoidable returns by:

- Investigating return reasons
- Identifying high-return products
- Identifying high-return categories
- Comparing return patterns across cities
- Prioritizing high-value returned products
- Monitoring refund value alongside return volumes
- Identifying preventable returns

---

## Recommendation 4: Strengthen Markets

Strengthen market performance by:

- Protecting Mumbai's strong performance
- Maintaining appropriate inventory availability
- Identifying the factors behind Mumbai's success
- Comparing Mumbai with Pune, Delhi and Bangalore
- Replicating successful strategies where appropriate
- Using localized product and inventory strategies

---

## Recommendation 5: Optimize Products Portfolio

Optimize the approximately **10K-product portfolio** by:

- Protecting strong performers such as Product 745 and Cat_5
- Identifying low-performing products
- Identifying high-AOV products
- Identifying high-return products
- Improving inventory allocation
- Considering SKU rationalization where appropriate

---

## Recommendation 6: Leverage Q4 Performance

Q4 is the strongest quarter by gross sales.

Management should:

- Analyze products driving Q4 performance
- Analyze leading categories
- Analyze leading cities
- Analyze customer segments contributing to Q4
- Identify successful Q4 demand patterns
- Apply successful strategies to weaker quarters
- Plan inventory ahead of weaker periods
- Plan promotions ahead of weaker periods
- Align marketing activities with identified demand patterns

---

# ⚠️ Data Limitations & Analytical Caveats

The following limitations define what can and cannot be reliably concluded from the dataset.

---

## 1. No Product Cost / COGS

The dataset does not provide explicit product cost or COGS.

Therefore:

- Gross profit cannot be calculated reliably.
- Gross margin cannot be calculated reliably.
- Net profit cannot be calculated reliably.
- True profitability cannot be evaluated.

Sales-related measures should therefore be described as **gross sales, transaction value or revenue**, not profit.

---

## 2. Customer Signup-Date Inconsistency

The data contains **120,020 orders** where the order date occurs before the associated customer signup date.

Therefore:

- Signup date is unreliable for customer tenure analysis.
- Signup date should not be used for reliable acquisition cohorts.
- Pre/post-signup behavior should not be interpreted from this field.

Orders are retained because the order data itself remains useful for sales and customer analysis.

---

## 3. No Return-Date Field

The returns table does not provide an actual return date.

Therefore:

- Actual monthly return trends cannot be calculated.
- Time-to-return cannot be calculated.
- Return timing cannot be reliably analyzed.

If returns are grouped using the original order date, the result represents **returned items associated with the original order period**, not the month in which the return actually occurred.

---

## 4. Multiple Return Records per Order Item

Multiple return records can reference the same order item.

Therefore:

- Return records should not automatically be treated as unique returned items.
- Distinct `order_item_id` should be used when measuring returned items.
- Refund amounts should be aggregated at the appropriate order-item grain.

---

## 5. Incomplete Final Time Period

The final transaction period may be incomplete compared with earlier full periods.

Therefore:

- End-of-series declines may appear artificially severe.
- Like-for-like comparisons should be preferred.
- Final-period trends should be interpreted cautiously.

---

## 6. Payment Data Limitations

The available payment data does not contain:

- Payment method
- Payment status

Therefore payment-method and payment-status analysis is not claimed.

---

## 7. Limited Shipment Attributes

The available shipment status categories are:

- SHIPPED
- DELIVERED
- LATE

Detailed information about the following is unavailable:

- Carrier
- Route
- Warehouse
- SLA
- Delivery partner

Therefore detailed root-cause analysis of late shipments cannot be performed from the current dataset.

---

## 8. Historical / Static Dataset

The dataset is historical and static rather than a live operational data feed.

The dashboards therefore represent historical business performance rather than real-time operational monitoring.

---

# ⚠️ Analytical Interpretation Rules

The following rules were applied to ensure that business findings remain consistent with what the dataset can reliably support.

---

## 1. Sales Calculation

Historical gross sales are calculated using:

`order_items.qty × order_items.price`

The transaction-level price from `order_items.price` is used rather than the master product price.

Gross sales should be interpreted as **transaction value/revenue**, not profit, because product cost/COGS is unavailable.

---

## 2. Promotion Analysis

Promotion comparisons are treated as **associations rather than causal relationships**.

Use:

- Promotion-associated sales
- Sales from promoted orders

Avoid claims such as:

- Promotions caused higher sales
- Promotions increased sales by a specific amount

The available data can identify differences between promoted and non-promoted orders but cannot establish causality.

---

## 3. Promotion Discounts

The available data does not clearly establish whether `order_items.price` represents the price before or after promotional discounts.

Therefore, `promotions.discount` should not automatically be subtracted again when calculating sales because this could result in **double-counting the discount**.

---

## 4. Payment Reconciliation

Differences between payment amounts and calculated order values should be treated as **reconciliation differences requiring investigation**.

A difference should not automatically be classified as a payment error or bad record without additional supporting information.

---

## 5. Refund Calculation

Multiple return/refund records can reference the same order item.

Therefore:

- Returned items are measured using distinct `order_item_id`
- Refund values should be aggregated at the appropriate order-item grain
- Return-record count should not automatically be interpreted as unique returned items

---

## 6. Return Rate

Return rate requires a clearly defined denominator.

For the order-item return rate used in this project:

`Return Rate = Distinct Returned Order Items ÷ Total Order Items × 100`

This prevents multiple return records for the same order item from inflating the return rate.

---

## 7. Return Timing

The dataset does not contain an actual return-date field.

Therefore, returns grouped using `order_date` represent:

**Returned items associated with the original order period**

They should not be interpreted as returns that actually occurred during that month or period.

---

## 8. Shipment & Return Analysis

Relationships between shipment status and returns are interpreted as **descriptive associations**.

For example, a higher return rate among late shipments does not prove that the late shipment caused the return.

Additional evidence would be required to establish causality.

---

## 9. Late Shipment Comparison

Absolute late-shipment counts should not be used alone to determine which city has the worst delivery performance.

Cities may have different shipment volumes, so **late-delivery rates** provide a more appropriate normalized comparison.

---

# 🔍 Supported vs Unsupported Analysis

## Supported Analysis

The available data supports:

- Gross sales / transaction value
- Order volume
- Average Order Value
- Units sold
- Customer purchase frequency
- Customer value
- Repeat-customer analysis
- Store and city performance
- Product performance
- Category performance
- Supplier sales distribution
- Descriptive promotion comparisons
- Payment amount analysis and reconciliation
- Shipment-status distribution
- Late-delivery analysis
- Distinct returned order items
- Return-rate analysis
- Aggregated refund analysis

---

## Unsupported Analysis

The available data does not reliably support:

- Gross profit
- Net profit
- Profit margin
- True profitability
- Reliable customer tenure using `signup_date`
- Reliable acquisition cohorts using `signup_date`
- Actual return-date trends
- Time-to-return analysis
- Causal claims that promotions caused higher sales
- Causal claims that shipment status caused returns
- Post-discount net sales without confirmed pricing semantics

---

# 🏆 Project Outcomes

This project demonstrates the ability to:

- Work with a multi-table retail data warehouse
- Perform structured SQL analysis
- Build and manage relational data models
- Develop business KPIs using DAX
- Build five interactive Power BI dashboards
- Analyze sales, stores, products and customers
- Evaluate shipment, return and refund performance
- Validate Power BI results independently using SQL
- Identify and resolve aggregation and filter-context issues
- Translate analytical findings into business insights
- Develop management recommendations
- Document data limitations and analytical caveats

---

# 💼 Skills Demonstrated

- Excel
- MySQL 8.0
- SQL
- Power BI
- DAX
- Data Modeling
- Data Validation
- KPI Development
- Sales Analytics
- Customer Analytics
- Product Analytics
- Operational Analytics
- Dashboard Development
- Data Visualization
- Business Intelligence
- Data Storytelling

---

# 📝 Conclusion

The **Multi-Branch Retail Performance & Operations Intelligence** project transforms retail data into a structured and validated business intelligence solution covering sales, stores, products, categories, customers, shipments, returns and refunds across Mumbai, Pune, Delhi and Bangalore.

The analysis highlights **~₹3.83B in gross sales, 29.77% YoY growth, a 98.56% repeat customer rate and a 33.29% late-delivery rate**, while Mumbai emerged as the strongest commercial market, Product 745 as the top product, Cat_5 as the leading category and Q4 as the strongest quarter.

The findings identify opportunities to **improve delivery reliability, increase customer value, reduce returns, strengthen market performance, optimize the product portfolio and leverage Q4 performance**.

Major Power BI KPIs and analytical outputs were independently validated against SQL results, while documented data limitations ensure that conclusions remain within what the dataset can reliably support.

Overall, the project demonstrates a complete **Data Analyst / Business Intelligence workflow** from initial data inspection and SQL analysis through data modeling, DAX, dashboard development, validation, business insights and management recommendations.

---

# 🗂️ Project Structure

```text
Multi-Branch_Retail_Performance_Operations_Analysis/
│
├── 01_Dataset/
│   └── Raw retail dataset
│
├── 02_Data_Model/
│   ├── Analytics_workflow_diagram.png
│   ├── Data_Dictionary.md
│   └── retail_er_diagram.png
│
├── 03_SQL/
│   ├── 01_Create_Tables.sql
│   ├── 02_Load_Data.sql
│   ├── 03_Data_Cleaning.sql
│   ├── 04_EDA.sql
│   ├── 05_Business_Queries.sql
│   ├── 06_Views.sql
│   ├── 07_Stored_Procedures.sql
│   └── 08_Indexes.sql
│
├── 04_PowerBI/
│   ├── D1_Executive_Overview.png
│   ├── D2_Store_Performance.png
│   ├── D3_Product_&_Category_Performance.png
│   ├── D4_Customer_Performance.png
│   ├── D5_Operations_&_Returns.png
│   └── Multi_Branch_Retail_Analysis.pbix
│
├── 05_Images/
│   ├── Analytics_workflow_diagram.png
│   ├── D1_Executive_Overview.png
│   ├── D2_Store_Performance.png
│   ├── D3_Product_&_Category_Performance.png
│   ├── D4_Customer_Performance.png
│   ├── D5_Operations_&_Returns.png
│   └── retail_er_diagram.png
│
├── 06_Documents/
│   ├── 01_Multi-Branch Retail Performance & Operations Intelligence Report.pdf
│   ├── 02_Project_Summary.pdf
│   ├── 03_Business_Insights.pdf
│   ├── 04_Business_Recommendations.pdf
│   ├── 05_Data_Limitations.pdf
│   └── README.md
│
└── 07_Presentation/
    ├── Multi-Branch Retail Performance & Operations Intelligence Presentation.pptx
    └── Multi-Branch Retail Performance & Operations Intelligence Presentation.pdf

---

# 👩‍💻 Author

**Abhirami Ananthakumar**

Data Analyst | Business Intelligence Analyst

### Core Skills

`SQL` `MySQL` `Power BI` `DAX` `Excel` `Data Wrangling` `Data Cleaning` `Data Modeling` `Data Validation` `Business Intelligence`

---

# 🔗 Project Links

**GitHub Repository:**  
[https://github.com/abhirami-ananthakumar/multi-branch-retail-performance-operations-analytics]

**LinkedIn:**  
[https://www.linkedin.com/in/abhirami-ananthakumar-8b83a5256]

---

⭐ If you found this project useful, feel free to explore the SQL analysis, Power BI dashboards and project documentation included in this repository.

