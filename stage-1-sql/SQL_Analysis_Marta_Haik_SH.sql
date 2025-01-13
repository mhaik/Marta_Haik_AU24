-- Task 3. Write SQL queries to perform the following tasks:


-- Retrieve the total sales amount for each product category for a specific time period

SELECT p.prod_category AS product_category, SUM(s.amount_sold) AS total_sales_amount
FROM sh.sales s
JOIN sh.products p ON s.prod_id = p.prod_id
WHERE s.time_id BETWEEN DATE '1998-01-01' AND DATE '1998-02-28'
GROUP BY p.prod_category
ORDER BY total_sales_amount DESC;


-- Calculate the average sales quantity by region for a particular product

SELECT co.country_region AS region, AVG(s.quantity_sold) AS average_sales_quantity
FROM sh.sales s
JOIN sh.customers c ON s.cust_id = c.cust_id
JOIN sh.countries co ON c.country_id = co.country_id
WHERE s.prod_id = (SELECT prod_id FROM sh.products WHERE prod_name = 'O/S Documentation Set - French')
GROUP BY co.country_region
ORDER BY average_sales_quantity DESC;


-- Find the top five customers with the highest total sales amount

SELECT c.cust_id, SUM(s.amount_sold) AS total_sales_amount,
c.cust_first_name || ' ' || c.cust_last_name AS customer_name
FROM sh.sales s
JOIN sh.customers c ON s.cust_id = c.cust_id
GROUP BY c.cust_id, customer_name
ORDER BY total_sales_amount DESC
LIMIT 5;