-- Task 1. Create a view
--Create a view called 'sales_revenue_by_category_qtr' that shows 
--the film category and total sales revenue for the current quarter and year. 
--The view should only display categories with at least one sale in the current quarter. 
--Note: when the next quarter begins, it will be considered as the current quarter.

DROP VIEW IF EXISTS sales_revenue_by_category_qtr; -- for reusability

CREATE VIEW sales_revenue_by_category_qtr AS
SELECT c.name AS film_category, SUM(p.amount) AS total_sales_revenue
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE EXTRACT(QUARTER FROM CURRENT_DATE) = EXTRACT(QUARTER FROM r.rental_date)
AND EXTRACT(YEAR FROM CURRENT_DATE) = EXTRACT(YEAR FROM r.rental_date)
GROUP BY c.name
HAVING SUM(p.amount) > 0; -- at least one sale

SELECT * FROM sales_revenue_by_category_qtr;


-- the table is empty because there are no rentals in 2024

SELECT r.rental_id, r.rental_date, f.title AS film_title, c.name AS category
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
ORDER BY r.rental_date DESC
LIMIT 10;


-- here i made a view with revenue for the first quarter of 2017

DROP VIEW IF EXISTS sales_revenue_by_category_qtr;

CREATE VIEW sales_revenue_by_category_qtr AS
WITH quarter_dates AS (
    SELECT DATE '2017-01-01' AS start_date,
    DATE '2017-04-01' AS end_date
)
SELECT c.name AS film_category, SUM(p.amount) AS total_sales_revenue
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
JOIN quarter_dates qd ON r.rental_date >= qd.start_date AND r.rental_date < qd.end_date
GROUP BY c.name
HAVING SUM(p.amount) > 0
ORDER BY total_sales_revenue DESC;

SELECT * FROM sales_revenue_by_category_qtr;






-- Task 2. Create a query language functions
--Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts 
--one parameter representing the current quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.

DROP FUNCTION IF EXISTS get_sales_revenue_by_category_qtr(integer, integer);

CREATE FUNCTION get_sales_revenue_by_category_qtr(current_quarter INT, current_year INT)
RETURNS TABLE(category TEXT, total_sales_revenue DECIMAL(7, 2)) AS $$
BEGIN
RETURN QUERY
SELECT c.name AS category, SUM(p.amount) AS total_sales_revenue
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE EXTRACT(QUARTER FROM r.rental_date) = current_quarter
AND EXTRACT(YEAR FROM r.rental_date) = current_year
GROUP BY c.name
HAVING SUM(p.amount) > 0
ORDER BY total_sales_revenue DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * 
FROM get_sales_revenue_by_category_qtr(1, 2017);






-- Task 3. Create procedure language functions
--Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 


DROP FUNCTION IF EXISTS most_popular_films_by_countries(TEXT[]);

CREATE FUNCTION most_popular_films_by_countries(countries TEXT[])
RETURNS TABLE(
	country TEXT,
	film_title TEXT,
	rating TEXT,
	language TEXT,
	length INT,
	release_year INT,
	rental_count INT
	) AS $$
BEGIN
RETURN QUERY
SELECT 
DISTINCT ON (co.country)
	co.country,
	f.title AS film_title,
	f.rating::TEXT, -- the types are really weird (like "USER-DEFINED") so I used casting on the problematic columns
	l.name::TEXT AS language, 
	f.length::INTEGER AS length, 
	f.release_year::INTEGER AS release_year, 
	COUNT(r.rental_id)::INTEGER AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN language l ON f.language_id = l.language_id
JOIN customer c ON r.customer_id = c.customer_id
JOIN address ad ON c.address_id = ad.address_id
JOIN city ci ON ad.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id
WHERE co.country = ANY(countries)
GROUP BY co.country, f.title, f.rating, l.name, f.length, f.release_year
ORDER BY co.country, rental_count DESC; -- my HAVING COUNT MAX was not working so i put the condition here
END;
$$ LANGUAGE plpgsql;

SELECT * 
FROM most_popular_films_by_countries(ARRAY['Afghanistan', 'Brazil', 'United States']);


-- checking the types

-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'film';



-- here is the HAVING attempt 

-- HAVING 
-- COUNT(r.rental_id) = (
-- SELECT MAX(rental_count)
-- FROM (
-- SELECT COUNT(r.rental_id) AS rental_count
-- FROM rental r
-- JOIN inventory i ON r.inventory_id = i.inventory_id
-- JOIN film f ON i.film_id = f.film_id
-- WHERE r.customer_id = r.customer_id
-- GROUP BY f.title
-- ) AS rental_counts
-- )





-- Task 4. Create procedure language functions
-- Create a function that generates a list of movies available in stock based on a partial title match 
-- (e.g., movies containing the word 'love' in their title). 
-- The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, 
-- return a message indicating that it was not found.
-- The function should produce the result set in the following format 
-- (note: the 'row_num' field is an automatically generated counter field, starting from 1 and incrementing for each entry, 
-- 	e.g., 1, 2, ..., 100, 101, ...)
	
DROP FUNCTION IF EXISTS films_in_stock_by_title(TEXT[]);

CREATE FUNCTION films_in_stock_by_title(partial_title TEXT[])
RETURNS TABLE (
row_num BIGINT,            
film_title TEXT,             
language TEXT,               
customer_name TEXT,         
returned_date DATE          
) AS $$
BEGIN
-- distinct returned films (if they are returned, they must be in stock)
RETURN QUERY
WITH distinct_rentals AS 
	(
	SELECT DISTINCT ON (f.title, c.customer_id, r.return_date)
	f.title AS film_title,
	l.name::TEXT AS language,
	c.first_name || ' ' || c.last_name AS customer_name,
	r.return_date::DATE AS returned_date
	FROM film f
	JOIN language l ON f.language_id = l.language_id
	JOIN inventory i ON f.film_id = i.film_id
	JOIN rental r ON i.inventory_id = r.inventory_id
	JOIN customer c ON r.customer_id = c.customer_id
	WHERE f.title ILIKE '%' || partial_title || '%'
	AND r.return_date IS NOT NULL  -- only films that have been returned
	ORDER BY f.title, c.customer_id, r.return_date DESC  -- most recent return date per film-customer pair
	)
SELECT 
ROW_NUMBER() OVER (ORDER BY distinct_rentals.film_title, distinct_rentals.returned_date) AS row_num,  -- row number generated
distinct_rentals.film_title,
distinct_rentals.language,
distinct_rentals.customer_name,
distinct_rentals.returned_date
FROM distinct_rentals
ORDER BY distinct_rentals.film_title, distinct_rentals.returned_date;

-- if no rows were returned, raise an exception
IF NOT FOUND THEN
RAISE EXCEPTION 'No movies with title containing "%"', partial_title;
END IF;
END;
$$ LANGUAGE plpgsql;


select * from films_in_stock_by_title('%love%');

--SELECT * FROM films_in_stock_by_title('%jajo%');







-- Task 5. Create procedure language functions
-- Create a procedure language function called 'new_movie' that takes a movie title as a parameter 
-- and inserts a new movie with the given title in the film table. The function should generate a 
-- new unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99. 
-- The release year and language are optional and by default should be current year and Klingon respectively. 
-- The function should also verify that the language exists in the 'language' table. 
-- Then, ensure that no such function has been created before; if so, replace it.

DROP FUNCTION IF EXISTS new_movie(TEXT, INTEGER, TEXT);

CREATE OR REPLACE FUNCTION new_movie(
movie_title TEXT,
release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
language_name TEXT DEFAULT 'Klingon'
)
RETURNS VOID AS $$ -- because function doesnt return a value
DECLARE
new_film_id INT;
language_id INT;
BEGIN
-- check if language exists
SELECT l.language_id INTO language_id
FROM language l
WHERE l.name = language_name;
IF NOT FOUND THEN
RAISE EXCEPTION 'Language % does not exist.', language_name;
END IF;

-- check if movie exists
IF EXISTS (SELECT 1 FROM film WHERE title = movie_title) THEN
RAISE EXCEPTION 'Movie with title % already exists.', movie_title;
END IF;

INSERT INTO film (title, rental_rate, rental_duration, replacement_cost, release_year, language_id)
VALUES (movie_title, 4.99, 3, 19.99, release_year, language_id)
RETURNING film_id INTO new_film_id;

IF NOT FOUND THEN
RAISE EXCEPTION 'Failed to insert new movie with title %', movie_title;
END IF;

RAISE NOTICE 'A new movie was added with title %', movie_title;
END;
$$ LANGUAGE plpgsql;


SELECT new_movie('Akademia Pana Kleksa', 2024, 'English');

SELECT * FROM film WHERE title = 'Akademia Pana Kleksa';
SELECT new_movie('DEVIL WEARS PRADA', 2006, 'English');