--Part 1: Write SQL queries to retrieve the following data

--All animation movies released between 2017 and 2019 with rate more than 1, alphabetical]

SELECT f.title
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE f.release_year BETWEEN 2017 AND 2019
AND f.rating IN ('G', 'PG', 'PG-13', 'R', 'NC-17') -- I'm not sure what "rate more than 1" means, so I assumed it just exists
-- I used (SELECT DISTINCT rating FROM film ORDER BY rating;) to find the ratings
AND c.name = 'Animation'
ORDER BY f.title ASC; -- ASC == alphabetical (would be ASC without specifying too, but it's for emphasizing)


--The revenue earned by each rental store since March 2017 (columns: address and address2 – as one column, revenue)

SELECT CONCAT(a.address, ', ', a.address2) AS one_column_adress, SUM(p.amount) AS revenue
FROM store s
INNER JOIN address a ON s.address_id = a.address_id
INNER JOIN inventory i ON s.store_id = i.store_id
INNER JOIN rental r ON i.inventory_id = r.inventory_id
INNER JOIN payment p ON r.rental_id = p.rental_id
WHERE p.payment_date >= '2017-03-01'
GROUP BY one_column_adress; -- so aggregation could work


--Top-5 actors by number of movies (released since 2015) they took part in (columns: first_name, last_name, 
--number_of_movies, sorted by number_of_movies in descending order)

SELECT a.first_name, a.last_name, COUNT(fa.film_id) AS number_of_movies
FROM actor a
INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN film f ON fa.film_id = f.film_id
WHERE f.release_year >= 2015
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;


--Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies,
--number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)

SELECT f.release_year,
SUM((c.name = 'Drama')::int) AS number_of_drama_movies,
-- my idea was (SUM(c.name = 'Drama')) but booleans can't be summed, and the error helped me to get it to switch to something (like int)
-- also, SUM should ignore NULL values
SUM((c.name = 'Travel')::int) AS number_of_travel_movies,
SUM((c.name = 'Documentary')::int) AS number_of_documentary_movies
FROM film f
LEFT JOIN film_category fc ON f.film_id = fc.film_id -- all films are in the results even if they don't belong to any category
LEFT JOIN category c ON fc.category_id = c.category_id
GROUP BY f.release_year
ORDER BY f.release_year DESC;


--For each client, display a list of horrors that he had ever rented (in one column, separated by commas),
--and the amount of money that he paid for it

SELECT c.first_name, c.last_name,
STRING_AGG(f.title, ', ') AS horrors_rented, -- one column of titles, separated by commma
SUM(p.amount) AS money_paid
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id
INNER JOIN payment p ON r.rental_id = p.rental_id
INNER JOIN inventory i ON r.inventory_id = i.inventory_id
INNER JOIN film_category fc ON i.film_id = fc.film_id
INNER JOIN film f ON fc.film_id = f.film_id
INNER JOIN category ca ON fc.category_id = ca.category_id
WHERE ca.name = 'Horror'
GROUP BY c.first_name, c.last_name
ORDER BY c.first_name, c.last_name;



--Part 2: Solve the following problems using SQL

--1. Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance. 
--Assumptions: staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
--if staff processed the payment then he works in the same store; take into account only payment_date

SELECT s.first_name, s.last_name, SUM(p.amount) AS revenue, store.store_id
FROM staff s
INNER JOIN payment p ON s.staff_id = p.staff_id
INNER JOIN rental r ON p.rental_id = r.rental_id
INNER JOIN inventory i ON r.inventory_id = i.inventory_id
INNER JOIN store ON store.store_id = s.store_id
WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
	-- I don't really understand how to implement the last store 
GROUP BY s.first_name, s.last_name, store.store_id
ORDER BY revenue DESC, s.first_name, s.last_name
LIMIT 3;

--2. Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies?
--To determine expected age please use 'Motion Picture Association film rating system

SELECT f.title, COUNT(r.rental_id) AS rental_count, f.rating
FROM film f
INNER JOIN inventory i ON f.film_id = i.film_id
INNER JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.title, f.rating
ORDER BY rental_count DESC
LIMIT 5;



--Part 3. Which actors/actresses didn't act for a longer period of time than the others? 

--V1: gap between the latest release_year and current year per each actor;

SELECT a.first_name, a.last_name,
EXTRACT(YEAR FROM CURRENT_DATE) - 
	(SELECT MAX(f.release_year) 
	FROM film f 
	INNER JOIN film_actor fa ON f.film_id = fa.film_id 
	WHERE fa.actor_id = a.actor_id) AS years_gap
FROM actor a
ORDER BY years_gap DESC
LIMIT 10;

--V2: gaps between sequential films per each actor;

-- I am unfortunately unable to do this approach. I don't know what to do