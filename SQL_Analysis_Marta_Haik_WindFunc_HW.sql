-- Task 1

-- Create a query to produce a sales report highlighting the top customers with the highest sales across different sales channels. 
-- This report should list the top 5 customers for each channel. 
-- Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' 
-- which represents the percentage of a customer's sales relative to the total sales within their respective channel.
-- Please format the columns as follows:
-- Display the total sales amount with two decimal places
-- Display the sales percentage with five decimal places and include the percent sign (%) at the end
-- Display the result for each channel in descending order of sales


WITH total_sales_per_channel AS (
    -- summing sales and grouping by channel to calculate total sales per channel
    SELECT 
        s.channel_id, 
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    GROUP BY s.channel_id
),

customer_sales AS ( -- next cte
    -- join of sales and total sales per channel to calculate the total sales for each customer
    SELECT 
        s.channel_id,
        s.cust_id,
        SUM(s.amount_sold) AS customer_sales,
        ts.total_sales,
        (SUM(s.amount_sold) / ts.total_sales) * 100 AS sales_percentage -- sales percentage by total sales
    FROM sh.sales s
    JOIN total_sales_per_channel ts ON s.channel_id = ts.channel_id
    GROUP BY s.channel_id, s.cust_id, ts.total_sales
),

ranked_customers AS ( -- another cte
    -- rank customers within each channel by sales amount (using ROW_NUMBER()) in descending order
    SELECT 
        cs.channel_id,
        cs.cust_id,
        cs.customer_sales,
        cs.sales_percentage,
        ROW_NUMBER() OVER (PARTITION BY cs.channel_id ORDER BY cs.customer_sales DESC) AS rank
    FROM customer_sales cs -- using cte above
)

-- top 5 customers per channel with formatted sales and percentage
SELECT 
    ch.channel_desc,
    cs.cust_id,
    cu.cust_first_name,
    cu.cust_last_name,
    ROUND(cs.customer_sales, 2) AS total_sales, -- total sales with 2 decimal places
    CONCAT(ROUND(cs.sales_percentage, 5), ' %') AS sales_percentage -- sales percentage with 5 decimal places and percent sign
FROM ranked_customers cs
JOIN sh.channels ch ON cs.channel_id = ch.channel_id  -- join with channels table for the channel description
JOIN sh.customers cu ON cs.cust_id = cu.cust_id  -- join with customers table to get customer details
WHERE cs.rank <= 5  -- top 5 customers per channel
ORDER BY ch.channel_desc, cs.customer_sales DESC;





-- Task 2
-- Create a query to retrieve data for a report that displays the total sales for all products in the 
-- Photo category in the Asian region for the year 2000. Calculate the overall report total and name it 'YEAR_SUM'
-- Display the sales amount with two decimal places
-- Display the result in descending order of 'YEAR_SUM'
-- For this report, consider exploring the use of the crosstab function.


CREATE EXTENSION IF NOT EXISTS tablefunc;


SELECT 
    product_name,
    q1, -- each quarter's sales
    q2,
    q3,
    q4,
    (COALESCE(q1, 0) + COALESCE(q2, 0) + COALESCE(q3, 0) + COALESCE(q4, 0)) AS year_sum -- yearly total
FROM crosstab(
    $$
    SELECT 
        p.prod_name AS product_name,
        t.calendar_quarter_number AS quarter,
        ROUND(SUM(s.amount_sold), 2) AS sales_amount
    FROM sh.sales s
    JOIN sh.products p ON s.prod_id = p.prod_id  -- join with products table for 'Photo' category
    JOIN sh.customers cu ON s.cust_id = cu.cust_id -- join with customers and countries for 'Asia'
    JOIN sh.countries co ON cu.country_id = co.country_id
    JOIN sh.times t ON s.time_id = t.time_id -- join with the times table
    WHERE 
        p.prod_category = 'Photo'
        AND co.country_region = 'Asia'
        AND t.calendar_year = 2000
    GROUP BY p.prod_name, t.calendar_quarter_number
    ORDER BY p.prod_name, t.calendar_quarter_number
    $$,
    -- quarter numbers to go through
    $$ VALUES (1), (2), (3), (4) $$
) AS ct(
    product_name TEXT, 
    q1 NUMERIC, 
    q2 NUMERIC, 
    q3 NUMERIC, 
    q4 NUMERIC
) -- column names for crosstab output
ORDER BY year_sum DESC; -- sort by yearly total in descending order





-- Task 3

-- Create a query to generate a sales report for customers ranked in the top 300 based on total sales 
-- in the years 1998, 1999, and 2001. The report should be categorized based on sales channels, 
-- and separate calculations should be performed for each channel.
-- Retrieve customers who ranked among the top 300 in sales for the years 1998, 1999, and 2001
-- Categorize the customers based on their sales channels
-- Perform separate calculations for each sales channel
-- Include in the report only purchases made on the channel specified
-- Format the column so that total sales are displayed with two decimal places


WITH customer_sales AS (
    SELECT 
        s.channel_id,
        s.cust_id, -- customer ID
        t.calendar_year, -- year of the sale
        SUM(s.amount_sold) AS total_sales  -- Sum of sales for each customer in a specific year and specific channel
    FROM sh.sales s
    JOIN sh.times t ON s.time_id = t.time_id  -- join with times table to get the sales year
    JOIN sh.customers cu ON s.cust_id = cu.cust_id  -- join with customers table to filter by customers later
    WHERE t.calendar_year IN (1998, 1999, 2001)  -- years 1998, 1999, and 2001
    GROUP BY s.channel_id, s.cust_id, t.calendar_year
),
	
ranked_customers AS (
    SELECT 
        cs.channel_id,
        cs.cust_id,
        cs.total_sales,  -- total sales amount for the customer
        ROW_NUMBER() OVER (PARTITION BY cs.channel_id ORDER BY cs.total_sales DESC) AS rank  -- rank customers with each channel
    FROM customer_sales cs  -- use the result of the customer_sales cte for ranking
)

SELECT
    c.channel_desc, -- channel description
    cu.cust_last_name,
    cu.cust_first_name,
    ROUND(cs.total_sales, 2) AS amount_sold  -- total sales (two decimal places)
FROM ranked_customers cs
JOIN sh.channels c ON cs.channel_id = c.channel_id  -- join with the channels table to get the channel description
JOIN sh.customers cu ON cs.cust_id = cu.cust_id   -- join with the customers table to get customer details
WHERE cs.rank <= 300  -- top 300 customers per channel
ORDER BY c.channel_desc, cs.total_sales  DESC;  -- order by channel description in descending order






-- Task 4

-- Create a query to generate a sales report for January 2000, February 2000, and March 2000 
-- specifically for the Europe and Americas regions.
-- Display the result by months and by product category in alphabetical order.


-- SELECT 
-- t.calendar_month_name AS month, 
-- p.prod_category AS product_category,
-- SUM(CASE WHEN co.country_region = 'Europe' THEN s.amount_sold ELSE 0 END) 
-- OVER (PARTITION BY t.calendar_month_name ORDER BY p.prod_category) AS europe_cumulative_sales,
-- SUM(CASE WHEN co.country_region = 'Americas' THEN s.amount_sold ELSE 0 END)
-- OVER (PARTITION BY t.calendar_month_name ORDER BY p.prod_category) AS americas_cumulative_sales
-- FROM sh.sales s -- join with the times table to filter for specific months
-- JOIN sh.times t ON s.time_id = t.time_id -- join with the products table to get the product categories
-- JOIN sh.products p ON s.prod_id = p.prod_id -- join with the customers and countries table to filter for Europe and Americas regions
-- JOIN sh.customers c ON s.cust_id = c.cust_id 
-- JOIN sh.countries co ON c.country_id = co.country_id
-- WHERE t.calendar_year = 2000 AND t.calendar_month_number IN (1, 2, 3) -- January, February, March 2000
-- AND co.country_region IN ('Europe', 'Americas') -- Europe and America region
-- GROUP BY t.calendar_month_name, p.prod_category, co.country_region, s.amount_sold -- all needed columns
-- ORDER BY t.calendar_month_name, p.prod_category;


-- The code above makes a lot of duplicates, it's faster and easier to write query without it, but I understand
-- the task is made so we could specifically practice window functions


SELECT 
    t.calendar_month_name AS month, 
    p.prod_category AS product_category,
    SUM(CASE WHEN co.country_region = 'Europe' THEN s.amount_sold ELSE 0 END) AS europe_sales, -- European sales
    SUM(CASE WHEN co.country_region = 'Americas' THEN s.amount_sold ELSE 0 END) AS americas_sales -- American sales
FROM sh.sales s -- join with the times table to filter for specific months
JOIN sh.times t ON s.time_id = t.time_id -- join with the products table to get the product categories
JOIN sh.products p ON s.prod_id = p.prod_id -- join with the customers and countries table to filter for Europe and Americas regions
JOIN sh.customers c ON s.cust_id = c.cust_id 
JOIN sh.countries co ON c.country_id = co.country_id
WHERE t.calendar_year = 2000 AND t.calendar_month_number IN (1, 2, 3) -- January, February, March 2000
AND co.country_region IN ('Europe', 'Americas') -- Europe and America region
GROUP BY t.calendar_month_name, p.prod_category
ORDER BY t.calendar_month_name, p.prod_category;
