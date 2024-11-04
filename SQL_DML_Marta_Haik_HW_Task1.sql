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

ALTER TABLE film
ADD CONSTRAINT unique_film_title UNIQUE (title);
-- unique constraint is for the ON CONFLICT to know what is a "conflict" (will not work otherwise) 

INSERT INTO film (title, rental_rate, rental_duration, language_id, last_update) -- wouldnt work without inserting language_id
VALUES
    ('DEVIL WEARS PRADA', 4.99, 1, 1, current_date),
    ('A DOG''S PURPOSE', 9.99, 2, 1, current_date),
    ('CRAZY RICH ASIANS', 19.99, 3, 1, current_date)
ON CONFLICT (title) DO NOTHING;

-- 2
-- Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).
-- Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.

-- temporary table to store the values
CREATE TEMP TABLE temp_actors (
    first_name VARCHAR(30),
    last_name VARCHAR(30)
);

INSERT INTO temp_actors (first_name, last_name)
VALUES 
    ('CONSTANCE', 'WU'), -- 1
    ('HENRY', 'GOLDING'), -- 2
    ('MERYL', 'STREEP'), -- 3
    ('ANNE', 'HATHAWAY'), -- 4
    ('EMILY', 'BLUNT'), -- 5
    ('DENNIS', 'QUAID'), -- 6
	('JOSH', 'GAD'); -- 7

-- inserting into actor table

ALTER TABLE actor
ADD CONSTRAINT unique_actor_name UNIQUE (first_name, last_name);
-- said that (first_name, last_name)=(SUSAN, DAVIS) is duplicated

INSERT INTO actor (first_name, last_name)
SELECT first_name, last_name
FROM temp_actors AS t
WHERE NOT EXISTS (
    SELECT 1 FROM actor AS a
    WHERE a.first_name = t.first_name AND a.last_name = t.last_name
);

-- associating actors with films in film_actor table
INSERT INTO film_actor (film_id, actor_id)
SELECT f.film_id, a.actor_id
FROM film AS f
JOIN actor AS a ON (a.first_name, a.last_name) IN (
    ('MERYL', 'STREEP'),
    ('ANNE', 'HATHAWAY'),
    ('EMILY', 'BLUNT')
) WHERE f.title = 'DEVIL WEARS PRADA'
UNION ALL
SELECT f.film_id, a.actor_id
FROM film AS f
JOIN actor AS a ON (a.first_name, a.last_name) IN (
    ('DENNIS', 'QUAID'),
	('JOSH', 'GAD')
) WHERE f.title = 'A DOG''S PURPOSE'
UNION ALL
SELECT f.film_id, a.actor_id
FROM film AS f
JOIN actor AS a ON (a.first_name, a.last_name) IN (
    ('CONSTANCE', 'WU'),
    ('HENRY', 'GOLDING')
) WHERE f.title = 'CRAZY RICH ASIANS';


-- 3
-- Add your favorite movies to any store's inventory.

INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, current_date -- store_id is either 1 or 2
FROM film AS f
WHERE f.title IN 
	('DEVIL WEARS PRADA', 
	'A DOG''S PURPOSE', 
	'CRAZY RICH ASIANS');

-- 4
-- Alter any existing customer in the database with at least 43 rental and 43 payment records. 
-- Change their personal data to yours (first name, last name, address, etc.). 
-- You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, 
-- as this can impact multiple records with the same address.

SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS rental_count, COUNT(p.payment_id) AS payment_count
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
HAVING COUNT(r.rental_id) >= 43 AND COUNT(p.payment_id) >= 43;

-- 1	"MARY"	"SMITH"	5	"1913 Hanoi Way"
SELECT c.customer_id, c.first_name, c.last_name, c.address_id, a.address
	FROM customer AS c
	JOIN address AS a ON c.address_id = a.address_id
	WHERE c.customer_id = 1)
	
UPDATE customer
SET first_name = 'MARTA',
    last_name = 'HAIK',
    email = 'marta.haik@example.com',
    address_id = (SELECT address_id FROM address WHERE address_id = 5), -- query above gives 5 here
    last_update = current_date
WHERE customer_id = (SELECT c.customer_id
                     FROM customer c
                     JOIN rental r ON c.customer_id = r.customer_id
                     JOIN payment p ON c.customer_id = p.customer_id
                     GROUP BY c.customer_id
                     HAVING COUNT(r.rental_id) >= 43 AND COUNT(p.payment_id) >= 43
                     LIMIT 1); -- first record/one person only
-- 5
-- Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'

-- SELECT * 
-- FROM rental 
-- WHERE customer_id = 
-- 	(SELECT customer_id 
-- 	FROM customer 
-- 	WHERE first_name = 'MARTA' AND last_name = 'HAIK');

DELETE FROM payment_p2017_01 WHERE customer_id = 1;
DELETE FROM payment_p2017_02 WHERE customer_id = 1;
DELETE FROM payment WHERE customer_id = 1;

DELETE FROM rental
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'MARTA' AND last_name = 'HAIK');

	
-- 6
-- Rent you favorite movies from the store they are in and pay for them 
-- (add corresponding records to the database to represent this activity)
-- (Note: to insert the payment_date into the table payment, you can create a new partition 
-- (see the scripts to install the training database ) or add records for the first half of 2017)

BEGIN;

INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
SELECT current_date, i.inventory_id, c.customer_id, s.staff_id
FROM inventory AS i
JOIN customer AS c ON c.first_name = 'MARTA' AND c.last_name = 'HAIK'
JOIN staff AS s ON s.staff_id = (SELECT staff_id FROM staff LIMIT 1) -- record of who facilitated the rental and payment (probably would
-- be needed in real life
WHERE i.film_id IN (
    SELECT film_id FROM film WHERE title IN ('DEVIL WEARS PRADA', 'A DOG''S PURPOSE', 'CRAZY RICH ASIANS')
);

-- a check
-- SELECT * FROM rental
-- WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'MARTA' AND last_name = 'HAIK')
-- ORDER BY rental_date DESC
-- LIMIT 10;

COMMIT; 


BEGIN;

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT c.customer_id, s.staff_id, r.rental_id, f.rental_rate, '2017-03-17' -- first half of 2017
FROM rental AS r
JOIN customer AS c ON c.first_name = 'MARTA' AND c.last_name = 'HAIK'
JOIN staff AS s ON s.staff_id = (SELECT staff_id FROM staff LIMIT 1)
JOIN film AS f ON f.film_id = r.inventory_id
WHERE r.rental_date = current_date;

-- SELECT *
-- FROM payment
-- WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'MARTA' AND last_name = 'HAIK')
-- AND payment_date = '2017-03-17';

COMMIT;