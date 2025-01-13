-- Task 1. Window Functions
-- Create a query to generate a report that identifies for each channel and throughout the entire period, the regions with the highest quantity of products sold (quantity_sold). 
-- The resulting report should include the following columns:
-- CHANNEL_DESC
-- COUNTRY_REGION
-- SALES: This column will display the number of products sold (quantity_sold) with two decimal places.
-- SALES %: This column will show the percentage of maximum sales in the region (as displayed in the SALES column) compared to the total sales for that channel. The sales percentage should be displayed with two decimal places and include the percent sign (%) at the end.
-- Display the result in descending order of SALES

	
WITH total_sales AS (
    SELECT
		c.channel_desc, 
        r.country_region,
        SUM(s.quantity_sold) AS total_region_sales 
		-- amount_sold is giving different results (compared to quantity_sold, q_s results are as in the example)
    FROM sh.sales s
    JOIN sh.channels c ON s.channel_id = c.channel_id -- for the channel_desc
    JOIN sh.customers cu ON s.cust_id = cu.cust_id -- for linking sales with countries
    JOIN sh.countries r ON cu.country_id = r.country_id -- for the region
    GROUP BY c.channel_desc, r.country_region
),

	
rank_sales AS (
    SELECT
        channel_desc,
        country_region,
        total_region_sales,
		-- rank regions by sales within each channel
        RANK() OVER (PARTITION BY channel_desc ORDER BY total_region_sales DESC) AS sales_rank,
		-- total sales for each channel
        SUM(total_region_sales) OVER (PARTITION BY channel_desc) AS total_channel_sales
    FROM total_sales
)

	
SELECT
    channel_desc,
    country_region,
    ROUND(total_region_sales, 2) AS sales,
    CONCAT(ROUND((total_region_sales * 100.0) / total_channel_sales, 2), '%') AS "sales %"
	-- percentage of total sales contributed by the region for the channel
FROM rank_sales
WHERE sales_rank = 1 -- filtering only the best for each channel
ORDER BY sales DESC;


-- Task 2. Window Functions
-- Identify the subcategories of products with consistently higher sales from 1998 to 2001 compared to the previous year. 
-- Determine the sales for each subcategory from 1998 to 2001.
-- Calculate the sales for the previous year for each subcategory.
-- Identify subcategories where the sales from 1998 to 2001 are consistently higher than the previous year.
-- Generate a dataset with a single column containing the identified prod_subcategory values.



WITH subcategory_sales AS (
	SELECT
	    p.prod_subcategory,
	    EXTRACT(YEAR FROM t.time_id) AS calendar_year,
	    CASE -- (sales - previous year sales); if the difference is positive then 1 (they are higher), otherwise 0
	    	WHEN (SUM(s.amount_sold) - COALESCE((LAG(sum(s.amount_sold), 1) OVER (PARTITION BY p.prod_subcategory)), 0)) > 0 THEN 1
			-- LAG() for the previous year for each subcategory (in case of no data, 0 instead of NULL with COALESCE)
	    	ELSE 0
	    END AS higher_sales
	FROM sh.sales s JOIN sh.times t ON s.time_id = t.time_id
	JOIN sh.products p ON s.prod_id = p.prod_id
	WHERE EXTRACT(YEAR FROM t.time_id) BETWEEN 1998 AND 2001
	GROUP BY p.prod_subcategory, EXTRACT(YEAR FROM t.time_id)
	ORDER BY p.prod_subcategory, EXTRACT(YEAR FROM t.time_id)

	
)
	
SELECT prod_subcategory
FROM subcategory_sales
GROUP BY prod_subcategory
HAVING SUM(higher_sales) > 3; -- higher_sales comparison starts from 1999 (1998 lacks prior year for comparison),
-- so 3 years are checked: 1999, 2000, 2001



-- Task 3. Window Frames
-- Create a query to generate a sales report for the years 1999 and 2000, focusing on quarters and product categories. In the report you have to  analyze the sales of products from the categories 'Electronics,' 'Hardware,' and 'Software/Other,' across the distribution channels 'Partners' and 'Internet'.
-- The resulting report should include the following columns:
-- CALENDAR_YEAR: The calendar year
-- CALENDAR_QUARTER_DESC: The quarter of the year
-- PROD_CATEGORY: The product category
-- SALES$: The sum of sales (amount_sold) for the product category and quarter with two decimal places
-- DIFF_PERCENT: Indicates the percentage by which sales increased or decreased compared to the first quarter of the year. For the first quarter, the column value is 'N/A.' The percentage should be displayed with two decimal places and include the percent sign (%) at the end.
-- CUM_SUM$: The cumulative sum of sales by quarters with two decimal places
-- The final result should be sorted in ascending order based on two criteria: first by 'calendar_year,' then by 'calendar_quarter_desc'; and finally by 'sales' descending



WITH quarter_sales AS (
    SELECT
        EXTRACT(YEAR FROM t.time_id) AS calendar_year,
        t.calendar_quarter_desc,
        p.prod_category,
        SUM(s.amount_sold) AS sales$
    FROM sh.sales s
	JOIN sh.times t ON s.time_id = t.time_id
    JOIN sh.products p ON s.prod_id = p.prod_id
    JOIN sh.channels c ON s.channel_id = c.channel_id
    WHERE EXTRACT(YEAR FROM t.time_id) IN (1999, 2000) -- specific years
        AND UPPER(p.prod_category) IN ('ELECTRONICS', 'HARDWARE', 'SOFTWARE/OTHER') -- specific productS
        AND UPPER(c.channel_desc) IN ('PARTNERS', 'INTERNET') -- specific channels
    GROUP BY EXTRACT(YEAR FROM t.time_id), t.calendar_quarter_desc, p.prod_category),

	
query_data AS (
    SELECT
        calendar_year,
        calendar_quarter_desc,
        prod_category,
        sales$,
        CASE
			-- 'N/A' for the first quarter since there's previous quarter for comparision
            WHEN ROW_NUMBER() OVER (PARTITION BY calendar_year, prod_category ORDER BY CALENDAR_quarter_desc) = 1 THEN 'N/A'
            -- percentage difference compared to the first quarter's sales value
			ELSE ROUND(((sales$ - FIRST_VALUE(sales$) OVER (PARTITION BY calendar_year, prod_category)) / first_value(sales$) 
			OVER (PARTITION BY calendar_year, prod_category ORDER BY calendar_quarter_desc)) * 100, 2) || '%' 
        END AS diff_percent,
		-- cumulative sum of sales up to the current quarter, from the beginning to the current quarter
        SUM(sales$) OVER (PARTITION BY calendar_year ORDER BY calendar_quarter_desc RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum$
    FROM quarter_sales
)

	
SELECT
    calendar_year,
    calendar_quarter_desc,
    prod_category,
    SUM(sales$) AS sales$, -- total sales for the quarter
    diff_percent, -- percentage change compared to the first quarter
    cum_sum$ -- cumulative sales summed up to the current quarter
FROM query_data
GROUP BY calendar_year, calendar_quarter_desc, prod_category, diff_percent, cum_sum$
ORDER BY calendar_year, calendar_quarter_desc, SUM(sales$) DESC;  -- by year, quarter, sales (descending)
