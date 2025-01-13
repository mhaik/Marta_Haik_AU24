-- Task 2. Implement role-based authentication model for dvd_rental database

--Create a new user with the username "rentaluser" and the password "rentalpassword". 
--Give the user the ability to connect to the database but no other permissions.

CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

--Grant "rentaluser" SELECT permission for the "customer" table. 
--Сheck to make sure this permission works correctly—write a SQL query to select all customers.

GRANT SELECT ON customer TO rentaluser;
SET ROLE rentaluser;
SELECT * FROM customer;
SET ROLE postgres;

--Create a new user group called "rental" and add "rentaluser" to the group. 
CREATE ROLE rental;
GRANT rental TO rentaluser;

--Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. 
--Insert a new row and update one existing row in the "rental" table under that role. 

GRANT INSERT ON rental TO rental;

SELECT * FROM rental
	
INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
VALUES (
DEFAULT, '2024-11-16 10:00:00', 2452, 459, '2024-11-26 11:15:00', 1, CURRENT_TIMESTAMP
)
ON CONFLICT DO NOTHING
RETURNING *;


SELECT * FROM rental WHERE return_date = '2024-11-26 11:15:00'

GRANT UPDATE ON rental TO rental;

UPDATE rental SET return_date = NOW() + INTERVAL '1 week'
WHERE rental_id = 32462;

--Revoke the "rental" group INSERT permission for the "rental" table. 
--Try to insert new rows into the "rental" table make sure this action is denied.

REVOKE INSERT ON rental FROM rental;

INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
VALUES (
DEFAULT, '2024-11-16 10:00:00', 1525, 549, '2024-11-26 11:15:00', 2, CURRENT_TIMESTAMP
)
ON CONFLICT DO NOTHING
RETURNING *;

-- Create a personalized role for any customer already existing in the dvd_rental database. 
-- The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
-- The customer's payment and rental history must not be empty. 

-- SELECT customer_id, first_name, last_name
-- FROM customer
-- WHERE customer_id IN (SELECT DISTINCT customer_id FROM rental)
-- AND customer_id IN (SELECT DISTINCT customer_id FROM payment);

DO $$
DECLARE
    role_name TEXT;
BEGIN
    -- loop through customers who have rental and payment history
    FOR role_name IN 
        SELECT 'client_' || LOWER(first_name) || '_' || LOWER(last_name) AS role_name
        FROM customer
        WHERE customer_id IN (
            SELECT customer_id
            FROM rental
            GROUP BY customer_id
            HAVING COUNT(*) > 0
        )
        AND customer_id IN (
            SELECT customer_id
            FROM payment
            GROUP BY customer_id
            HAVING COUNT(*) > 0
        )
    LOOP
        -- check if the role already exists, and create it if not
        IF NOT EXISTS (
            SELECT 1 FROM pg_roles WHERE rolname = role_name
        ) THEN
            EXECUTE 'CREATE ROLE ' || role_name || ' NOLOGIN';
        END IF;
    END LOOP;
END $$;


SET ROLE client_patricia_johnson;

SELECT * FROM rental;


--Task 3. Implement row-level security
--Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. 
--Write a query to make sure this user sees only their own data.

SET ROLE postgres;

DROP POLICY IF EXISTS rental_select_policy_p ON rental;
DROP POLICY IF EXISTS rental_insert_policy_p ON rental;
DROP POLICY IF EXISTS rental_update_policy_p ON rental;
DROP POLICY IF EXISTS rental_delete_policy_p ON rental;

DROP POLICY IF EXISTS payment_select_policy_p ON payment;
DROP POLICY IF EXISTS payment_insert_policy_p ON payment;
DROP POLICY IF EXISTS payment_update_policy_p ON payment;
DROP POLICY IF EXISTS payment_delete_policy_p ON payment;


ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

-- only the customer can access their own rows:

CREATE POLICY rental_select_policy_p ON rental
FOR SELECT
USING (customer_id = (SELECT customer_id FROM customer WHERE UPPER(first_name) = 'PATRICIA' AND UPPER(last_name) = 'JOHNSON'));

CREATE POLICY rental_insert_policy_p ON rental
FOR INSERT
WITH CHECK (customer_id = (SELECT customer_id FROM customer WHERE UPPER(first_name) = 'PATRICIA' AND UPPER(last_name) = 'JOHNSON'));

CREATE POLICY rental_update_policy_p ON rental
FOR UPDATE
USING (customer_id = (SELECT customer_id FROM customer WHERE UPPER(first_name) = 'PATRICIA' AND UPPER(last_name) = 'JOHNSON'));

CREATE POLICY rental_delete_policy_p ON rental
FOR DELETE
USING (customer_id = (SELECT customer_id FROM customer WHERE UPPER(first_name) = 'PATRICIA' AND UPPER(last_name) = 'JOHNSON'));

-- only the customer can access their own payment records

CREATE POLICY payment_select_policy_p ON payment
FOR SELECT
USING (customer_id = (SELECT customer_id FROM customer WHERE UPPER(first_name) = 'PATRICIA' AND UPPER(last_name) = 'JOHNSON'));

CREATE POLICY payment_insert_policy_p ON payment
FOR INSERT
WITH CHECK (customer_id = (SELECT customer_id FROM customer WHERE UPPER(first_name) = 'PATRICIA' AND UPPER(last_name) = 'JOHNSON'));

CREATE POLICY payment_update_policy_p ON payment
FOR UPDATE
USING (customer_id = (SELECT customer_id FROM customer WHERE UPPER(first_name) = 'PATRICIA' AND UPPER(last_name) = 'JOHNSON'));

CREATE POLICY payment_delete_policy_p ON payment
FOR DELETE
USING (customer_id = (SELECT customer_id FROM customer WHERE UPPER(first_name) = 'PATRICIA' AND UPPER(last_name) = 'JOHNSON'));


SET ROLE client_patricia_johnson;

SELECT distinct customer_id FROM rental;