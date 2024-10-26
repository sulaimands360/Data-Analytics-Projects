# Ad-Hoc Analytics Project with MySQL

## Project Overview

This project involves answering a series of ad-hoc analytical questions for a fictional business scenario, aimed at providing insights into customer operations, product performance, sales, and other key business metrics. The data is queried using **MySQL** and presented in a structured format. The project showcases my SQL querying skills and ability to derive business insights from data.

The task was originally part of the **Codebasics Resume Project Challenge**.

## Questions and Solutions

### 1. List of Markets where “Atliq Exclusive” Operates in the APAC Region
**Objective:** Find all the markets in which the customer “Atliq Exclusive” operates within the APAC region.

**Solution:**  
We filtered the data based on the customer and region fields to extract the markets specific to "Atliq Exclusive" in the APAC region.

```sql
-- Query to find the markets for 'Atliq Exclusive' in the APAC region
SELECT DISTINCT market
FROM customers
WHERE customer_name = 'Atliq Exclusive' AND region = 'APAC';
```

---

### 2. Percentage Increase in Unique Products (2021 vs 2020)
**Objective:** Calculate the percentage increase in the number of unique products from 2020 to 2021.

**Solution:**  
We counted the distinct products for each year and calculated the percentage change.

```sql
-- Query to calculate unique product increase
WITH product_count AS (
    SELECT
        YEAR(order_date) AS year,
        COUNT(DISTINCT product_code) AS unique_products
    FROM orders
    WHERE YEAR(order_date) IN (2020, 2021)
    GROUP BY YEAR(order_date)
)
SELECT
    p2020.unique_products AS unique_products_2020,
    p2021.unique_products AS unique_products_2021,
    ROUND(((p2021.unique_products - p2020.unique_products) / p2020.unique_products) * 100, 2) AS percentage_chg
FROM product_count p2020
JOIN product_count p2021 ON p2020.year = 2020 AND p2021.year = 2021;
```

---

### 3. Unique Product Counts by Segment
**Objective:** Generate a report with unique product counts for each segment, sorted in descending order.

**Solution:**  
We grouped the data by segment and counted the distinct products for each.

```sql
-- Query to get unique product counts by segment
SELECT segment, COUNT(DISTINCT product_code) AS product_count
FROM orders
GROUP BY segment
ORDER BY product_count DESC;
```

---

### 4. Segment with the Highest Increase in Unique Products (2021 vs 2020)
**Objective:** Determine which segment saw the largest increase in unique products between 2021 and 2020.

**Solution:**  
We calculated the distinct product counts for both years, then compared the differences for each segment.

```sql
-- Query to find segment with highest increase in unique products
WITH product_segment_count AS (
    SELECT
        segment,
        YEAR(order_date) AS year,
        COUNT(DISTINCT product_code) AS unique_products
    FROM orders
    WHERE YEAR(order_date) IN (2020, 2021)
    GROUP BY segment, YEAR(order_date)
)
SELECT
    ps2020.segment,
    ps2020.unique_products AS product_count_2020,
    ps2021.unique_products AS product_count_2021,
    (ps2021.unique_products - ps2020.unique_products) AS difference
FROM product_segment_count ps2020
JOIN product_segment_count ps2021
    ON ps2020.segment = ps2021.segment AND ps2020.year = 2020 AND ps2021.year = 2021
ORDER BY difference DESC;
```

---

### 5. Products with the Highest and Lowest Manufacturing Costs
**Objective:** Identify the products with the highest and lowest manufacturing costs.

**Solution:**  
We retrieved the products with the maximum and minimum manufacturing costs using appropriate sorting.

```sql
-- Query to find products with highest and lowest manufacturing costs
SELECT product_code, product, manufacturing_cost
FROM products
ORDER BY manufacturing_cost DESC
LIMIT 1
UNION ALL
SELECT product_code, product, manufacturing_cost
FROM products
ORDER BY manufacturing_cost ASC
LIMIT 1;
```

---

### 6. Top 5 Customers with the Highest Pre-Invoice Discount in India (2021)
**Objective:** Find the top 5 customers in India who received the highest average pre-invoice discount percentage in 2021.

**Solution:**  
We filtered the data for the Indian market in 2021 and computed the average discount, selecting the top 5 customers.

```sql
-- Query to find top 5 customers by average discount in India for 2021
SELECT customer_code, customer_name, AVG(pre_invoice_discount_pct) AS average_discount_percentage
FROM orders
WHERE market = 'India' AND YEAR(order_date) = 2021
GROUP BY customer_code, customer_name
ORDER BY average_discount_percentage DESC
LIMIT 5;
```

---

### 7. Gross Sales for “Atliq Exclusive” by Month
**Objective:** Provide a monthly breakdown of gross sales for “Atliq Exclusive” to identify performance trends.

**Solution:**  
We grouped the data by month and year to calculate the gross sales.

```sql
-- Query to get gross sales for 'Atliq Exclusive' by month
SELECT 
    MONTH(order_date) AS month,
    YEAR(order_date) AS year,
    SUM(gross_sales_amount) AS gross_sales_amount
FROM orders
WHERE customer_name = 'Atliq Exclusive'
GROUP BY MONTH(order_date), YEAR(order_date)
ORDER BY year, month;
```

---

### 8. Quarter with Maximum Total Sold Quantity (2020)
**Objective:** Identify the quarter in 2020 with the maximum total sold quantity.

**Solution:**  
We grouped the data by quarter and calculated the total quantity sold.

```sql
-- Query to find the quarter with the maximum total sold quantity in 2020
SELECT QUARTER(order_date) AS quarter, SUM(total_sold_quantity) AS total_sold_quantity
FROM orders
WHERE YEAR(order_date) = 2020
GROUP BY QUARTER(order_date)
ORDER BY total_sold_quantity DESC
LIMIT 1;
```

---

### 9. Channel with the Highest Gross Sales (2021) and its Contribution Percentage
**Objective:** Determine which sales channel brought in the most gross sales in 2021 and its percentage contribution.

**Solution:**  
We calculated the gross sales for each channel and their contribution percentages.

```sql
-- Query to find the channel with the highest gross sales and its contribution
WITH total_sales AS (
    SELECT SUM(gross_sales_amount) AS total_gross_sales
    FROM orders
    WHERE YEAR(order_date) = 2021
)
SELECT 
    channel,
    SUM(gross_sales_amount) / 1000000 AS gross_sales_mln,
    ROUND((SUM(gross_sales_amount) / (SELECT total_gross_sales FROM total_sales)) * 100, 2) AS percentage
FROM orders
WHERE YEAR(order_date) = 2021
GROUP BY channel
ORDER BY gross_sales_mln DESC;
```

---

### 10. Top 3 Products by Total Sold Quantity for Each Division (2021)
**Objective:** Get the top 3 products in each division by total sold quantity for 2021.

**Solution:**  
We ranked the products by total sold quantity within each division and selected the top 3.

```sql
-- Query to get top 3 products by sold quantity in each division
WITH ranked_products AS (
    SELECT 
        division,
        product_code,
        product,
        SUM(total_sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY division ORDER BY SUM(total_sold_quantity) DESC) AS rank_order
    FROM orders
    WHERE YEAR(order_date) = 2021
    GROUP BY division, product_code, product
)
SELECT division, product_code, product, total_sold_quantity, rank_order
FROM ranked_products
WHERE rank_order <= 3;
```

---

## Conclusion

This project demonstrated various SQL techniques, including filtering, aggregating, joining, and ranking data to answer complex business questions. The queries are optimized for readability and performance, providing insights into market operations, product performance, customer behavior, and sales trends.

You can review the SQL scripts and results in more detail in the [final_queries.sql](final_queries.sql) file.

