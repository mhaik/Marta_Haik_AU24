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
    COALESCE(q1, 0) AS q1, -- each quarter's sales
    COALESCE(q2, 0) AS q2,
    COALESCE(q3, 0) AS q3,
    COALESCE(q4, 0) AS q4,
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


WITH ranked_customers AS (
    SELECT 
        s.channel_id,
        s.cust_id,
        t.calendar_year,
        SUM(s.amount_sold) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.channel_id, t.calendar_year ORDER BY SUM(s.amount_sold) DESC
        ) AS rank -- rank customers based on total sales per channel and year
    FROM sh.sales s
    JOIN sh.times t ON s.time_id = t.time_id -- matching sales data to the corresponding time data
    WHERE t.calendar_year IN (1998, 1999, 2001) -- specific years
    GROUP BY s.channel_id, s.cust_id, t.calendar_year
	
top_customers AS (
    SELECT rc.channel_id, rc.cust_id -- sales channel, customer id
    FROM ranked_customers rc
    WHERE rc.rank <= 300 -- only customers ranked in the top 300 for each channel and year
    GROUP BY rc.channel_id, rc.cust_id
    HAVING COUNT(DISTINCT rc.calendar_year) = 3 -- must be for every year
)

SELECT
    c.channel_desc, -- channel description
    cu.cust_last_name,
    cu.cust_first_name,
    ROUND(SUM(s.amount_sold), 2) AS amount_sold -- total sales (two decimal places)
FROM top_customers tc
JOIN sh.sales s ON tc.channel_id = s.channel_id AND tc.cust_id = s.cust_id
JOIN sh.times t ON s.time_id = t.time_id
JOIN sh.channels c ON tc.channel_id = c.channel_id -- join with channels for channel description
JOIN sh.customers cu ON tc.cust_id = cu.cust_id -- join with customers for customer details
WHERE t.calendar_year IN (1998, 1999, 2001) -- sales from the specified years
GROUP BY c.channel_desc, cu.cust_last_name, cu.cust_first_name
ORDER BY c.channel_desc, amount_sold DESC; -- order by channel description descending (and total sales)



-- Task 4

-- Create a query to generate a sales report for January 2000, February 2000, and March 2000 
-- specifically for the Europe and Americas regions.
-- Display the result by months and by product category in alphabetical order.


SELECT DISTINCT
    t.calendar_month_name AS month,
    p.prod_category AS product_category,
    SUM(CASE WHEN co.country_region = 'Europe' THEN s.amount_sold ELSE 0 END) 
    OVER (PARTITION BY t.calendar_month_name, p.prod_category) AS europe_sales, -- European sales
    SUM(CASE WHEN co.country_region = 'Americas' THEN s.amount_sold ELSE 0 END) 
    OVER (PARTITION BY t.calendar_month_name, p.prod_category) as americas_sales -- American sales
FROM sh.sales s
JOIN sh.times t ON s.time_id = t.time_id -- join to filter by time (month, year)
JOIN sh.products p ON s.prod_id = p.prod_id -- join to get product categories
JOIN sh.customers c ON s.cust_id = c.cust_id -- join to customers table
JOIN sh.countries co ON c.country_id = co.country_id -- join to countries table for region info
WHERE t.calendar_year = 2000 
AND t.calendar_month_number IN (1, 2, 3) -- January, February, March 2000
AND co.country_region IN ('Europe', 'Americas') -- Europe and America region
ORDER BY t.calendar_month_name, p.prod_category;