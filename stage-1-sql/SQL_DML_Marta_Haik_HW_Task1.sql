-- Task 1

-- Note: 
-- All new & updated records must have 'last_update' field set to current_date.
-- Double-check your DELETEs and UPDATEs with SELECT query before committing the transaction!!! 
-- Your scripts must be rerunnable/reusable and don't produces duplicates. 
-- You can use WHERE NOT EXISTS, IF NOT EXISTS, ON CONFLICT DO NOTHING, etc.
-- Don't hardcode IDs. Instead of construction INSERT INTO … VALUES use INSERT INTO … SELECT …
-- Don't forget to add RETURNING
-- Please add comments why you chose a particular way to solve each tasks.

-- 1
-- Choose your top-3 favorite movies and add them to the 'film' table 
-- (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
-- Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.

INSERT INTO film (title, rental_rate, rental_duration, language_id, last_update)
SELECT 'DEVIL WEARS PRADA', 4.99, 7, l.language_id, current_date
FROM language l 
WHERE UPPER(l.name) = UPPER('English')
AND NOT EXISTS (
    SELECT 1 
    FROM film f
    WHERE UPPER(f.title) = 'DEVIL WEARS PRADA'
)
ON CONFLICT DO NOTHING
RETURNING *;

SELECT * FROM film WHERE title = 'DEVIL WEARS PRADA';

-- repeated for the other new records

INSERT INTO film (title, rental_rate, rental_duration, language_id, last_update)
SELECT 'A DOG''S PURPOSE', 9.99, 14, l.language_id, current_date
FROM language l 
WHERE UPPER(l.name) = UPPER('English')
AND NOT EXISTS (
    SELECT 1 
    FROM film f
    WHERE UPPER(f.title) = 'A DOG''S PURPOSE'
)
ON CONFLICT DO NOTHING
RETURNING *;

INSERT INTO film (title, rental_rate, rental_duration, language_id, last_update)
SELECT 'CRAZY RICH ASIANS', 19.99, 21, l.language_id, current_date
FROM language l 
WHERE UPPER(l.name) = UPPER('English')
AND NOT EXISTS (
    SELECT 1 
    FROM film f
    WHERE UPPER(f.title) = 'CRAZY RICH ASIANS'
)
ON CONFLICT DO NOTHING
RETURNING *;


-- 2
-- Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).
-- Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.

-- first, actor table

WITH actors_to_add (first_name, last_name) AS ( -- cte to store them
VALUES
    ('CONSTANCE', 'WU'),
    ('HENRY', 'GOLDING'),
    ('MERYL', 'STREEP'),
    ('ANNE', 'HATHAWAY'),
    ('EMILY', 'BLUNT'),
    ('DENNIS', 'QUAID'),
    ('JOSH', 'GAD')
	)
INSERT INTO actor (first_name, last_name, last_update)
SELECT first_name, last_name, current_date
FROM actors_to_add
WHERE NOT EXISTS ( --actor will be added only if no matching actor already exists
	SELECT 1 -- here can be anything, it matters if something is returned or not
	FROM actor
	WHERE UPPER(actor.first_name) = UPPER(actors_to_add.first_name)
    AND UPPER(actor.last_name) = UPPER(actors_to_add.last_name)
	)
ON CONFLICT DO NOTHING
RETURNING *;

SELECT first_name, last_name
FROM actor
WHERE (first_name, last_name) IN (
    ('CONSTANCE', 'WU'),
    ('HENRY', 'GOLDING'),
    ('MERYL', 'STREEP'),
    ('ANNE', 'HATHAWAY'),
    ('EMILY', 'BLUNT'),
    ('DENNIS', 'QUAID'),
    ('JOSH', 'GAD'),
	);



-- film_actor table

INSERT INTO film_actor (actor_id, film_id)
SELECT a.actor_id, f.film_id
FROM actor a
JOIN film f ON UPPER(f.title) = UPPER('DEVIL WEARS PRADA')
WHERE (
	(UPPER(a.first_name) = UPPER('MERYL') AND UPPER(a.last_name) = UPPER('STREEP')) OR
	(UPPER(a.first_name) = UPPER('ANNE') AND UPPER(a.last_name) = UPPER('HATHAWAY')) OR
	(UPPER(a.first_name) = UPPER('EMILY') AND UPPER(a.last_name) = UPPER('BLUNT'))
      )
AND NOT EXISTS (
    SELECT 1
    FROM film_actor fa
    WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
)
ON CONFLICT (actor_id, film_id) DO NOTHING
RETURNING *;

INSERT INTO film_actor (actor_id, film_id)
SELECT a.actor_id, f.film_id
FROM actor a
JOIN film f ON UPPER(f.title) = UPPER('A DOG''S PURPOSE')
WHERE (
	(UPPER(a.first_name) = UPPER('DENNIS') AND UPPER(a.last_name) = UPPER('QUAID')) OR
	(UPPER(a.first_name) = UPPER('JOSH') AND UPPER(a.last_name) = UPPER('GAD'))
      )
AND NOT EXISTS (
    SELECT 1
    FROM film_actor fa
    WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
)
ON CONFLICT (actor_id, film_id) DO NOTHING
RETURNING *;

INSERT INTO film_actor (actor_id, film_id)
SELECT a.actor_id, f.film_id
FROM actor a
JOIN film f ON UPPER(f.title) = UPPER('CRAZY RICH ASIANS')
WHERE (
	(UPPER(a.first_name) = UPPER('CONSTANCE') AND UPPER(a.last_name) = UPPER('WU')) OR
	(UPPER(a.first_name) = UPPER('HENRY') AND UPPER(a.last_name) = UPPER('GOLDING'))
      )
AND NOT EXISTS (
    SELECT 1
    FROM film_actor fa
    WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
)
ON CONFLICT (actor_id, film_id) DO NOTHING
RETURNING *;

SELECT fa.actor_id, fa.film_id
FROM film_actor fa
JOIN film f ON fa.film_id = f.film_id
WHERE UPPER(f.title) = UPPER('DEVIL WEARS PRADA');

-- 3
-- Add your favorite movies to any store's inventory.


INSERT INTO inventory (film_id, store_id)
SELECT f.film_id, s.store_id
FROM film f
JOIN store s ON s.store_id = 1
WHERE UPPER(f.title) IN (UPPER('DEVIL WEARS PRADA'), UPPER('A DOG''S PURPOSE'), UPPER('CRAZY RICH ASIANS'))
AND NOT EXISTS (
    SELECT *
    FROM inventory i
    WHERE i.film_id = f.film_id
    AND i.store_id = s.store_id
	)
ON CONFLICT DO NOTHING
RETURNING *;

-- 4
-- Alter any existing customer in the database with at least 43 rental and 43 payment records. 
-- Change their personal data to yours (first name, last name, address, etc.). 
-- You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, 
-- as this can impact multiple records with the same address.

-- first, fixing the main query
BEGIN;

-- SELECT c.customer_id, c.first_name, c.last_name, c.address_id,
-- COUNT(DISTINCT r.rental_id) AS rental_count, 
-- COUNT(DISTINCT p.payment_id) AS payment_count
-- FROM customer c
-- LEFT JOIN rental r ON c.customer_id = r.customer_id -- different joins, not losing data
-- LEFT JOIN payment p ON r.rental_id = p.rental_id
-- GROUP BY c.customer_id
-- HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
-- LIMIT 1;


UPDATE customer
SET first_name = 'MARTA',
last_name = 'HAIK',
email = 'marta.haik@example.com',
address_id = (SELECT address_id FROM address WHERE address_id = 6),
last_update = current_date
WHERE customer_id = (
	SELECT c.customer_id
	FROM customer c
	LEFT JOIN rental r ON c.customer_id = r.customer_id
	LEFT JOIN payment p ON r.rental_id = p.payment_id
	GROUP BY c.customer_id
	HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
	LIMIT 1
	)
ON CONFLICT DO NOTHING
RETURNING *;


SELECT *
FROM customer
WHERE email = 'marta.haik@example.com';



-- 5
-- Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'

SELECT *
FROM customer
WHERE email = 'marta.haik@example.com';

DELETE FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer WHERE UPPER(email) = UPPER('marta.haik@example.com')
);

DELETE FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer WHERE UPPER(email) = UPPER('marta.haik@example.com')
);

-- can't because it too connected to customer table

-- DELETE FROM address
-- WHERE address_id = (SELECT address_id FROM customer WHERE email = 'marta.haik@example.com' LIMIT 1);


	
-- 6
-- Rent you favorite movies from the store they are in and pay for them 
-- (add corresponding records to the database to represent this activity)
-- (Note: to insert the payment_date into the table payment, you can create a new partition 
-- (see the scripts to install the training database ) or add records for the first half of 2017)

INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
SELECT 
	current_date, 
	i.inventory_id, 
	c.customer_id, 
	s.staff_id
FROM inventory i
JOIN film f ON UPPER(f.title) IN (UPPER('DEVIL WEARS PRADA'), UPPER('A DOG''S PURPOSE'), UPPER('CRAZY RICH ASIANS'))
JOIN customer c ON UPPER(c.first_name) = UPPER('MARTA') AND UPPER(c.last_name) = UPPER('HAIK')
JOIN staff s ON s.staff_id = 2
WHERE NOT EXISTS (
    SELECT 1
    FROM rental r
    WHERE r.customer_id = c.customer_id 
	AND r.inventory_id = i.inventory_id 
	AND r.rental_date = current_date
)
ON CONFLICT DO NOTHING
RETURNING *;

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    c.customer_id,  
    s.staff_id,  
    r.rental_id,  
    f.rental_rate,  
    '2017-03-17'  
FROM rental r
JOIN customer c ON c.customer_id = r.customer_id  
JOIN staff s ON s.staff_id = r.staff_id  
JOIN film f ON f.film_id = r.inventory_id  
WHERE NOT EXISTS (
    SELECT 1 
    FROM payment p
    WHERE p.customer_id = c.customer_id
	AND p.staff_id = s.staff_id
	AND p.rental_id = r.rental_id
	AND p.payment_date = '2017-03-17' -- exact match for payment date
)
ON CONFLICT DO NOTHING
RETURNING *;

COMMIT;