                       --Assignment Tasks

                            --Task 1
-- Build the Sales Detail Dataset (6 marks)
--Management needs a detailed sales dataset for analysis. Return one row per order item containing:
--order_id and order_date
--customer full name
--store name
--staff full name
--product name
--category name
--brand name
--quantity, list_price, discount
--calculated net_line_revenue

--Include only completed orders (order_status = 4). Sort the result from newest order to oldest.



use BikeStores

SELECT 
    o.order_id,
    o.order_date,
    c.first_name + ' ' + c.last_name AS Customer_full_name,
    s.store_name,
    st.first_name + ' ' + st.last_name AS Staff_full_name,
    p.product_name,
    cat.category_name,
    b.brand_name,
    oi.quantity,
    oi.list_price,
    oi.discount,
   (oi.quantity * oi.list_price * (1 - oi.discount)) AS net_line_revenue  
FROM sales.orders AS o
inner join sales.customers AS c
ON o.customer_id = c.customer_id
inner join sales.stores as s
ON o.store_id = s.store_id
inner join sales.staffs as st
ON o.staff_id = st.staff_id
inner join sales.order_items as oi
ON o.order_id = oi.order_id
inner join production.products as p
ON oi.product_id = p.product_id
inner join production.categories as cat
ON p.category_id = cat.category_id
inner join production.brands as b
ON p.brand_id = b.brand_id;

                     --Task 2
-- Store Performance Summary (5 marks)
--Create a store-level performance report for completed orders showing:
--store name
--number of distinct orders
--total units sold
--total net revenue
--average order value
--Return one row per store and order the stores from highest to lowest total net revenue.


    
SELECT 
    s.store_name,
    count(distinct o.order_id) as total_orders,
    sum(oi.quantity) as total_units_sold,
    sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_net_revenue,
    sum(oi.quantity * oi.list_price * (1 - oi.discount)) / count(distinct o.order_id) 
      as average_order_value
FROM sales.stores as s
inner join sales.orders as o
   on s.store_id = o.store_id
inner join sales.order_items as oi
  on o.order_id = oi.order_id
WHERE o.order_status = 4
group by 
  s.store_id,
 s.store_name
order by 
 total_net_revenue desc
                              --Task 3
--High-Value Customers (5 marks)
--Management wants to identify high-value customers. Return customers whose total completed-order spending is greater than the average total spending of customers who have completed orders.

--Show customer_id, customer name, completed order count, and total spending. Order the result by total spending descending.


WITH CustomerSpending as (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        count(o.order_id) as completed_order_count,
        sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_spending
    FROM sales.customers c
    join sales.orders o ON c.customer_id = o.customer_id
    join sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 4 
    GROUP BY 
 c.customer_id,
 c.first_name, 
 c.last_name 
)
SELECT 
 customer_id,
 first_name,
 last_name,
  completed_order_count,
 total_spending
FROM CustomerSpending
WHERE total_spending > (
    SELECT AVG(total_spending) 
    FROM CustomerSpending
);

--Task 4 — Inventory Risk Report (5 marks)
--Operations wants to identify inventory risk. Return products where the stock quantit
--y is below 5 in at least one store.
--Show product name, store name, current quantity, category name, and brand name. Products with zero stock should appear first, 
--followed by the lowest remaining quantities.


SELECT 
    p.product_name,
    s.store_name,
    st.quantity AS current_quantity,
    c.category_name,
    b.brand_name
FROM production.products p
join production.stocks st ON p.product_id = st.product_id
join sales.stores s ON st.store_id = s.store_id
join production.categories c ON p.category_id = c.category_id
join production.brands b ON p.brand_id = b.brand_id
where  st.quantity < 5
order by 
    st.quantity asc,
    p.product_name asc;



--    Task 5 — Top Products Within Each Category (6 marks)
-- For each product category, identify the top 3 products by total net revenue from completed orders.

--Return category name, product name, total units sold, total net revenue, and the product's position within its category. Tied products must receive the same position and the next position should not contain gaps.

WITH CategoryRevenue as (
    SELECT 
        c.category_name,
        p.product_name,
        sum(oi.quantity) AS total_units_sold,
        sum(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue,
        dense_rank() OVER (
            PARTITION BY c.category_name 
            ORDER BY sum(oi.quantity * oi.list_price * (1 - oi.discount)) DESC
        ) AS product_position
    FROM production.products p
    join production.categories c ON p.category_id = c.category_id
    join sales.order_items oi ON p.product_id = oi.product_id
    join sales.orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 4
    GROUP BY 
        c.category_name,
        p.product_name
)
SELECT 
    category_name,
    product_name,
    total_units_sold,
    total_net_revenue,
    product_position
FROM CategoryRevenue
WHERE product_position <= 3
ORDER BY 
    category_name asc,
    product_position asc;

--Task 6 — Monthly Sales Trend (6 marks)
--Create a monthly sales trend for completed orders.

--For each calendar month return:
--year
--month
--total net revenue
--previous month's total net revenue
--revenue change from the previous month

--The first month may have NULL for the previous-month comparison. Sort chronologically.


WITH MonthlySales AS (
    SELECT 
        YEAR(o.order_date) AS [year],
        MONTH(o.order_date) AS [month],
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 4 
    GROUP BY 
        YEAR(o.order_date),
        MONTH(o.order_date)
)
SELECT 
    [year],
    [month],
    total_net_revenue,
    LAG(total_net_revenue, 1) OVER (
        ORDER BY [year] ASC, [month] ASC
    ) AS previous_month_total_net_revenue,
    total_net_revenue - LAG(total_net_revenue, 1) OVER (
        ORDER BY [year] ASC, [month] ASC
    ) AS revenue_change
FROM MonthlySales
ORDER BY 
    [year] ASC,
    [month] ASC;

                      --Task 7
-- Reusable Reporting View (4 marks)
--Create a view named sales.vw_customer_sales_summary that returns one row per customer and includes:
--customer_id
--customer full name
--total number of completed orders
--total units purchased
--total net revenue
--most recent completed order date

--Customers with no completed orders must still be represented where possible, with appropriate zero/NULL values.

DROP VIEW IF EXISTS sales.vw_customer_sales_summary;
GO

CREATE VIEW sales.vw_customer_sales_summary AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
    COUNT(DISTINCT CASE WHEN o.order_status = 4 THEN o.order_id END) AS total_completed_orders,
    ISNULL(SUM(CASE WHEN o.order_status = 4 THEN oi.quantity END), 0) AS total_units_purchased,
    ISNULL(SUM(CASE WHEN o.order_status = 4 THEN oi.quantity * oi.list_price * (1 - oi.discount) END), 0) AS total_net_revenue,
    MAX(CASE WHEN o.order_status = 4 THEN o.order_date END) AS most_recent_completed_order_date
FROM sales.customers c
LEFT JOIN sales.orders o 
    ON c.customer_id = o.customer_id
LEFT JOIN sales.order_items oi 
    ON o.order_id = oi.order_id
GROUP BY 
    c.customer_id,
    c.first_name,
    c.last_name;
GO

SELECT * FROM sales.vw_customer_sales_summary;

--Task 8 — Safe Data Modification (4 marks)
--A customer with customer_id = 1 has requested that their phone number be changed to '(999) 555-0101'.

--Write SQL that performs this update inside an explicit transaction. Include a validation query after the UPDATE and show how the change can be rolled back during testing so the assessment database is not permanently changed.



BEGIN TRANSACTION;

UPDATE sales.customers
SET phone = '(999) 555-0101'
WHERE customer_id = 1;

SELECT customer_id, first_name, last_name, phone
FROM sales.customers
WHERE customer_id = 1;

ROLLBACK TRANSACTION;
SELECT customer_id, first_name, last_name, phone
FROM sales.customers
WHERE customer_id = 1;

--Task 9 — Store Sales Procedure (6 marks)
--Create a stored procedure named sales.usp_store_sales_report with these input parameters:
--@store_id
--@start_date
--@end_date

--The procedure should return completed-order sales for the requested store and date range, grouped by product. Return product name, total units sold, and total net revenue, ordered by revenue descending.

--Add appropriate error handling for invalid date ranges where @start_date is later than @end_date.

GO
CREATE OR ALTER PROCEDURE sales.usp_store_sales_report
    @store_id INT,
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Date Range Validation (Error Handling)
    IF @start_date > @end_date
    BEGIN
        RAISERROR('Invalid Date Range: @start_date cannot be later than @end_date.', 16, 1);
        RETURN;
    END

    -- 2. Report Query
    SELECT 
        p.product_name,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN production.products p ON oi.product_id = p.product_id
    WHERE o.store_id = @store_id
      AND o.order_status = 4 -- Completed orders
      AND o.order_date >= @start_date
      AND o.order_date <= @end_date
    GROUP BY 
        p.product_name
    ORDER BY 
        total_net_revenue DESC;
END;
GO

EXEC sales.usp_store_sales_report 
    @store_id = 1, 
    @start_date = '2016-01-01', 
    @end_date = '2016-12-31';

--    Task 10 — Management Insight Query (3 marks)
--Write one additional SQL query that you believe would provide useful insight to BikeStores management using at least three tables.

--Below the query, add a SQL comment of no more than three lines explaining:
--1. the business question,
--2. what the result measures, and
--3. why management should care about it.


SELECT 
    s.store_name,
    CONCAT(st.first_name, ' ', st.last_name) AS staff_member,
    COUNT(DISTINCT o.order_id) AS total_orders_processed,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue_generated
FROM sales.staffs st
JOIN sales.stores s ON st.store_id = s.store_id
JOIN sales.orders o ON st.staff_id = o.staff_id
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 4 -- Completed orders
GROUP BY 
    s.store_name,
    st.first_name,
    st.last_name
ORDER BY 
    total_revenue_generated DESC;

    /* 
Business Question: Which staff members generate the highest revenue across stores for completed orders?
Measures: Total completed order volume and total net sales revenue generated per sales representative.
Management Value: Helps identify top sales performers for incentives and highlight stores needing staff training or resource reallocation.
*/
