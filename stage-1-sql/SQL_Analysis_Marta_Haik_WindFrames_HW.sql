-- Task 1
-- Create a query for analyzing the annual sales data for the years 1999 to 2001, focusing on different sales channels and regions: 
-- 'Americas,' 'Asia,' and 'Europe.' 
-- The resulting report should contain the following columns:
-- AMOUNT_SOLD: This column should show the total sales amount for each sales channel
-- % BY CHANNELS: In this column, we should display the percentage of total sales for each channel 
-- (e.g. 100% - total sales for Americas in 1999, 63.64% - percentage of sales for the channel “Direct Sales”)
-- % PREVIOUS PERIOD: This column should display the same percentage values as in the '% BY CHANNELS' column 
-- but for the previous year
-- % DIFF: This column should show the difference between the '% BY CHANNELS' and '% PREVIOUS PERIOD' columns, 
-- indicating the change in sales percentage from the previous year.
-- The final result should be sorted in ascending order based on three criteria: first by 'country_region,' 
-- then by 'calendar_year,' and finally by 'channel_desc'


WITH sales_data AS (
    SELECT
        r.country_region,
        t.calendar_year,
        c.channel_desc,
        SUM(s.amount_sold) AS amount_sold, -- total sales for specific channel/region/year
        SUM(SUM(s.amount_sold)) OVER (PARTITION BY r.country_region, t.calendar_year) AS total_sales_per_year
        -- total sales across all channels for a region/year
    FROM sh.sales s
    JOIN sh.times t ON s.time_id = t.time_id
    JOIN sh.channels c ON s.channel_id = c.channel_id
    JOIN sh.customers cu ON s.cust_id = cu.cust_id
    JOIN sh.countries r ON cu.country_id = r.country_id
    WHERE t.calendar_year BETWEEN 1998 AND 2001 -- include 1998 to calculate LAG for 1999
    AND r.country_region IN ('Americas', 'Asia', 'Europe') -- specific regions
    GROUP BY r.country_region, t.calendar_year, c.channel_desc -- for aggregation
),
	
query_data AS (
    SELECT
        country_region, -- region
        calendar_year, -- year
        channel_desc, -- channel
        amount_sold, -- total sales for this channel/region/year
        ROUND((amount_sold / total_sales_per_year) * 100, 2) AS "% BY CHANNELS",
        -- percentage of total sales by channel
        LAG(ROUND((amount_sold / total_sales_per_year) * 100, 2)) 
        OVER (PARTITION BY country_region, channel_desc ORDER BY calendar_year) AS "% PREVIOUS PERIOD",
        -- LAG to get the percentage from the previous year
        ROUND(ROUND((amount_sold / total_sales_per_year) * 100, 2) - 
		LAG(ROUND((amount_sold / total_sales_per_year) * 100, 2)) 
		OVER (PARTITION BY country_region, channel_desc ORDER BY calendar_year), 2) AS "% DIFF"
        -- difference between this year percentage and the previous year percentage
    FROM sales_data
)
	
SELECT
    country_region,
    calendar_year,
    channel_desc,
    amount_sold,
    "% BY CHANNELS",
    COALESCE("% PREVIOUS PERIOD", 0) AS "% PREVIOUS PERIOD",  -- replace NULL with 0
    COALESCE("% DIFF", 0) AS "% DIFF" -- replace NULL with 0
FROM query_data
WHERE calendar_year BETWEEN 1999 AND 2001 -- filter out 1998 now
ORDER BY country_region, calendar_year, channel_desc;




-- Task 2
-- You need to create a query that meets the following requirements:
-- Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
-- Include a column named CUM_SUM to display the amounts accumulated during each week.
-- Include a column named CENTERED_3_DAY_AVG to show the average sales for 
-- the previous, current, and following days using a centered moving average.
-- For Monday, calculate the average sales based on the weekend sales (Saturday and Sunday) as well as Monday and Tuesday.
-- For Friday, calculate the average sales on Thursday, Friday, and the weekend.
-- Ensure that your calculations are accurate for the beginning of week 49 and the end of week 51.



SELECT
    t.calendar_week_number,
    t.time_id,
    TO_CHAR(t.time_id, 'Day') AS day_name, -- makes id into day names (e.g. Monday)
    SUM(s.amount_sold) AS sales, -- total sales for the day
    SUM(SUM(s.amount_sold)) OVER ( -- cumulative sum of sales for each week
        PARTITION BY t.calendar_week_number -- for each week
        ORDER BY t.time_id -- by the day
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW -- all previous rows (till 6th) + the current row
    ) AS cum_sum,   
    ROUND((CASE 
		WHEN UPPER(t.day_name) = UPPER('Monday') THEN 
			AVG(SUM(s.amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN 
			INTERVAL '2' DAY PRECEDING AND INTERVAL '1' DAY FOLLOWING) -- Weekend, Monday, Tuesday
		WHEN UPPER(t.day_name) = UPPER('Friday') THEN 
			AVG(SUM(s.amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN 
			INTERVAL '1' DAY PRECEDING AND INTERVAL '2' DAY FOLLOWING) -- Thursday, Friday, Weekend
		ELSE 
			AVG(SUM(s.amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN 
			INTERVAL '1' DAY PRECEDING AND INTERVAL '1' DAY FOLLOWING) -- others
    END), 2) AS centered_3_day_avg
FROM sh.sales s
JOIN sh.times t ON s.time_id = t.time_id
WHERE t.calendar_year = 1999 AND t.calendar_week_number IN (49, 50, 51) -- weeks 49, 50, 51
GROUP BY t.calendar_week_number, t.time_id
ORDER BY t.calendar_week_number, t.time_id; -- first week number, then by days




-- Task 3
-- Please provide 3 instances of utilizing window functions that include a frame clause, using RANGE, ROWS, and GROUPS modes. 
-- Additionally, explain the reason for choosing a specific frame type for each example. 
-- This can be presented as a single query or as three distinct queries.


-- RANGE
-- query provides a clear picture of how sales are performing in each country over time
-- and could help in identifying patterns or trends in sales data within specific countries (or some other condition)


WITH weekly_sales AS (
    SELECT
        t.time_id,  -- each day
        c.country_name,  -- country name
        SUM(s.amount_sold) AS daily_sales  -- daily total sales
    FROM sh.sales s
    JOIN sh.times t ON s.time_id = t.time_id  -- for time information
    JOIN sh.customers cu ON s.cust_id = cu.cust_id  -- links sales to customers
    JOIN sh.countries c ON cu.country_id = c.country_id -- to get the country
    WHERE t.calendar_year = 1999  -- data in 1999
    GROUP BY t.time_id, c.country_name
)


SELECT
    time_id,
    country_name,
    daily_sales,
    SUM(daily_sales) OVER (  -- cumulative sales on a 7 day window
        PARTITION BY country_name  --for each country
        ORDER BY time_id
        RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW  -- current day and the 7 preceding days
    ) AS cumulative_7_day_sales
FROM weekly_sales
ORDER BY country_name, time_id;




-- ROWS
-- This query helps the business monitor sales trends over time, very similarly to range example above,
-- but it's 3 days average to keep a very strict eye to the performance


-- total sales for each day
WITH daily_sales AS (
    SELECT t.time_id,  -- each day
    SUM(s.amount_sold) AS daily_sales  -- total sales
    FROM sh.sales s
    JOIN sh.times t ON s.time_id = t.time_id  
    WHERE t.calendar_year = 1999  -- data in 1999
    GROUP BY t.time_id
)


SELECT
    time_id,
    daily_sales,  -- total sales for that specific day
    AVG(daily_sales) OVER (  -- average sales over a 3 day window
        ORDER BY time_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW  -- previous 2 days + the current day
    ) AS rolling_3_day_avg
FROM daily_sales
ORDER BY time_id;



-- GROUPS

-- Here query identifies top performers among specific categories (Electronics, Hardware, Software/Other),
-- allowing businesses to see which products are the best sellers or what to marketize better

SELECT
    p.prod_name,
    p.prod_category,
    SUM(s.amount_sold) AS total_sales,  -- total sales for each product
    -- ranking function to rank products based on total sales within their category
    RANK() OVER (
        ORDER BY SUM(s.amount_sold) DESC  -- highest first
        GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING  -- current product, the one before and the one after for ranking
    ) AS sales_rank  -- rank to each product based on total sales
FROM sh.sales s
JOIN sh.products p ON s.prod_id = p.prod_id 
WHERE p.prod_category = 'Electronics' OR p.prod_category = 'Hardware' OR p.prod_category = 'Software/Other'  -- specific categories
GROUP BY p.prod_name, p.prod_category
ORDER BY total_sales DESC;