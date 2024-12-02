CREATE SCHEMA IF NOT EXISTS museum_schema;
SET search_path TO museum_schema;


-- Table creation


CREATE TABLE IF NOT EXISTS museum_schema.Storage (
    storage_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location VARCHAR(100) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    space_taken INT
);

CREATE TABLE IF NOT EXISTS museum_schema.Artifacts (
    artifact_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    storage_id INT NOT NULL,
    name VARCHAR(100) NOT NULL DEFAULT 'Anonymous',
    style VARCHAR(100) NOT NULL,
    creation_date DATE,
    artist VARCHAR(100) NOT NULL,
    FOREIGN KEY (storage_id) REFERENCES Storage(storage_id)
);

CREATE TABLE IF NOT EXISTS museum_schema.Exhibition (
    exhibition_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(200) UNIQUE NOT NULL,
    start_date DATE CHECK (start_date > '2024-07-01'),
    end_date DATE CHECK (end_date IS NULL OR end_date > start_date)
);

CREATE TABLE IF NOT EXISTS museum_schema.Exhibition_Artifacts (
    exhibition_id INT,
    artifact_id INT,
    PRIMARY KEY (exhibition_id, artifact_id),
    FOREIGN KEY (exhibition_id) REFERENCES Exhibition(exhibition_id),
    FOREIGN KEY (artifact_id) REFERENCES Artifacts(artifact_id)
);

CREATE TABLE IF NOT EXISTS museum_schema.Employees (
    employee_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    job VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS museum_schema.Maintenance (
    maintenance_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    artifact_id INT NOT NULL,
    employee_id INT NOT NULL,
    date_performed DATE,
    next_due_date DATE,
    FOREIGN KEY (artifact_id) REFERENCES Artifacts(artifact_id),
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);

CREATE TABLE IF NOT EXISTS museum_schema.Tickets (
    ticket_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    exhibition_id INT NOT NULL,
    price DECIMAL(4, 2) NOT NULL CHECK (price > 0),
    ticket_type VARCHAR(15) NOT NULL,
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (exhibition_id) REFERENCES Exhibition(exhibition_id)
);



-- Altering table to add constraints

-- 'space_taken' in Storage does not exceed 'capacity' and is not negative
ALTER TABLE museum_schema.Storage
ADD CONSTRAINT check_storage_space_taken CHECK (space_taken >= 0 AND space_taken <= capacity);

-- 'creation_date' in Artifacts is not in the future
ALTER TABLE museum_schema.Artifacts
ADD CONSTRAINT check_artifact_creation_date CHECK (creation_date <= CURRENT_DATE);

-- 'start_date' in Exhibition is after 1st July 2024
ALTER TABLE museum_schema.Exhibition
ADD CONSTRAINT check_exhibition_start_date CHECK (start_date > '2024-07-01');

-- 'ticket_type' in Tickets is a from a certain type
ALTER TABLE museum_schema.Tickets
ADD CONSTRAINT check_ticket_type CHECK (ticket_type IN ('Normal', 'Discounted', 'VIP'));

-- 'next_due_date' in Maintenance must be greater than 'date_performed'
ALTER TABLE museum_schema.Maintenance
ADD CONSTRAINT check_maintenance_due_date CHECK (next_due_date IS NULL OR next_due_date > date_performed);



-- Populating the tables

INSERT INTO museum_schema.Storage (location, capacity)
SELECT location, capacity
FROM (VALUES 
    ('Paris Main Gallery', 200),
    ('Milan Archive', 200),
    ('New York Boutique Storage', 150),
    ('Tokyo Storage Facility', 150),
    ('London Design Studio', 120),
    ('LA Showcase Storage', 120)
) AS new_data(location, capacity)
WHERE NOT EXISTS (
    SELECT 1 FROM museum_schema.Storage s WHERE s.location = new_data.location
)
RETURNING *;


INSERT INTO museum_schema.Artifacts (storage_id, name, style, creation_date, artist)
SELECT s.storage_id, a.name, a.style, a.creation_date::DATE, a.artist
FROM (
    VALUES
    ('Paris Main Gallery', 'Lady Dior Bag', 'Accessories', '2020-01-15', 'Christian Dior'),
    ('Milan Archive', 'Bar Suit Ensemble', 'Haute Couture', '1947-02-12', 'Christian Dior'),
    ('New York Boutique Storage', 'J’Adore Perfume Bottle', 'Fragrance', '1999-09-20', 'John Galliano'),
    ('Tokyo Storage Facility', 'Dior Oblique Saddle Bag', 'Accessories', '2018-05-30', 'Maria Grazia Chiuri'),
    ('London Design Studio', 'New Look Dress', 'Haute Couture', '1947-03-12', 'Christian Dior'),
    ('LA Showcase Storage', 'Dior Homme Suit', 'Menswear', '2005-06-11', 'Hedi Slimane')
) AS a(location, name, style, creation_date, artist)
JOIN museum_schema.Storage s ON s.location = a.location
WHERE NOT EXISTS (
    SELECT 1 
    FROM museum_schema.Artifacts art 
    WHERE art.name = a.name
)
RETURNING *;


INSERT INTO museum_schema.Exhibition (title, start_date, end_date)
SELECT title, start_date::DATE, end_date::DATE
FROM (
    VALUES
    ('Christian Dior: Designer of Dreams', '2024-08-01', '2024-12-01'),
    ('Dior and Japan: The Art of Couture', '2024-08-15', '2024-10-15'),
    ('Revolutionary Dior Silhouettes', '2024-09-01', '2024-11-15'),
    ('Dior Accessories: Timeless Elegance', '2024-09-10', '2024-11-20'),
    ('Evolution of Dior Fragrances', '2024-10-01', '2024-11-30'),
    ('Dior and Modern Menswear', '2024-11-01', NULL)
) AS new_exhibitions(title, start_date, end_date)
ON CONFLICT (title) DO NOTHING
RETURNING *;


INSERT INTO museum_schema.Employees (name, surname, job)
SELECT name, surname, job
FROM (
    VALUES
    ('Marie', 'Curie', 'Director'),
    ('Lucie', 'Daouphars', 'Intern'),
    ('Monica', 'Belluci', 'Guide'),
    ('Charlize', 'Theron', 'Technician'),
    ('Natalie', 'Portman', 'Conservator'),
    ('Tom', 'Ford', 'Guide')
) AS new_employees(name, surname, job)
WHERE NOT EXISTS (
    SELECT 1 FROM museum_schema.Employees e WHERE e.name = new_employees.name AND e.surname = new_employees.surname
)
RETURNING *;

	
INSERT INTO museum_schema.Maintenance (artifact_id, employee_id, date_performed, next_due_date)
SELECT a.artifact_id, e.employee_id, m.date_performed::DATE, m.next_due_date::DATE
FROM (
    VALUES
    ('Lady Dior Bag', 'Marie', 'Curie', '2024-09-01', '2024-12-01'),
    ('Bar Suit Ensemble', 'Marie', 'Curie', '2024-09-10', '2024-12-10'),
    ('J’Adore Perfume Bottle', 'Monica', 'Belluci', '2024-10-01', '2024-12-30'),
    ('Dior Oblique Saddle Bag', 'Lucie', 'Daouphars', '2024-10-15', '2025-01-15'),
    ('New Look Dress', 'Charlize', 'Theron', '2024-11-01', NULL),
    ('Dior Homme Suit', 'Natalie', 'Portman', '2024-11-20', '2025-02-20')) AS m(name1, name2, surname, date_performed, next_due_date)
JOIN museum_schema.Artifacts a ON a.name = m.name1
JOIN museum_schema.Employees e ON e.name = m.name2 AND e.surname = m.surname
WHERE NOT EXISTS (
    SELECT 1
    FROM museum_schema.Maintenance mt
    WHERE mt.artifact_id = a.artifact_id
	AND mt.date_performed = m.date_performed::DATE
)
RETURNING *;


INSERT INTO museum_schema.Tickets (exhibition_id, price, ticket_type, purchase_date)
SELECT e.exhibition_id, t.price, t.ticket_type, t.purchase_date::DATE
FROM (
    VALUES
    ('Christian Dior: Designer of Dreams', 20.00, 'Normal', '2024-09-15'),
    ('Dior and Japan: The Art of Couture', 15.00, 'Discounted', '2024-09-20'),
    ('Revolutionary Dior Silhouettes', 50.00, 'VIP', '2024-10-01'),
    ('Dior Accessories: Timeless Elegance', 20.00, 'Normal', '2024-10-15'),
    ('Evolution of Dior Fragrances', 50.00, 'VIP', '2024-11-01'),
    ('Dior and Modern Menswear', 20.00, 'Normal', '2024-11-20')
) AS t(title, price, ticket_type, purchase_date)
JOIN museum_schema.Exhibition e ON e.title = t.title
ON CONFLICT DO NOTHING
RETURNING *;


-- Create a function that updates data in one of your tables.

CREATE OR REPLACE FUNCTION museum_schema.update_table_data(
    p_table_name TEXT,
    p_primary_key_column TEXT,
    p_primary_key_value INT,
    p_column_name TEXT,
    p_new_value TEXT
) RETURNS VOID AS $$
DECLARE 
    sql_query TEXT;
BEGIN
    sql_query := 'UPDATE ' || p_table_name || 
                 ' SET ' || p_column_name || ' = $1 ' || 
                 ' WHERE ' || p_primary_key_column || ' = $2';
    EXECUTE sql_query USING p_new_value, p_primary_key_value;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM employees WHERE surname = 'Ford';

SELECT museum_schema.update_table_data(
    'Employees',  -- table name
    'employee_id',  -- primary key column 
    (SELECT employee_id FROM museum_schema.Employees WHERE name = 'Tom' AND surname = 'Ford'), -- id
    'name',  -- column to update
    'Jennifer'  -- new value
);


SELECT * FROM employees WHERE surname = 'Ford';


-- Create a function that adds a new transaction to your transaction table. 

CREATE OR REPLACE FUNCTION museum_schema.add_transaction(
    p_exhibition_id INT,
    p_price DECIMAL(4,2),
    p_ticket_type VARCHAR(15),
    p_purchase_date DATE
) RETURNS TABLE(ticket_id INT, exhibition_id INT, price DECIMAL, ticket_type VARCHAR, purchase_date DATE) AS $$
BEGIN
    RETURN QUERY
    INSERT INTO museum_schema.Tickets (exhibition_id, price, ticket_type, purchase_date)
    SELECT p_exhibition_id, p_price, p_ticket_type, p_purchase_date
    WHERE NOT EXISTS (
        SELECT 1 
        FROM museum_schema.Tickets t
        WHERE t.exhibition_id = p_exhibition_id 
		AND t.price = p_price 
		AND t.ticket_type = p_ticket_type 
		AND t.purchase_date = p_purchase_date
    ) RETURNING Tickets.ticket_id, Tickets.exhibition_id, Tickets.price, Tickets.ticket_type, Tickets.purchase_date;
END;
$$ LANGUAGE plpgsql;


SELECT *
FROM museum_schema.add_transaction(1, 20.00, 'Normal', '2024-12-01');
-- When I try to use query for ID above, I have quite some problems with table column names being in conflict with the function,
-- so I separatly searched for ID:

-- SELECT exhibition_id 
-- FROM museum_schema.Exhibition 
-- WHERE title = 'Christian Dior: Designer of Dreams';

SELECT * FROM museum_schema.Tickets WHERE purchase_date = '2024-12-01';

-- Create a view that presents analytics for the most recently added quarter in your database. 


CREATE VIEW museum_schema.recently_added_quarter_analytics AS
SELECT 
    EXTRACT(QUARTER FROM e.start_date) AS quarter,
    EXTRACT(YEAR FROM e.start_date) AS year,
    COUNT(DISTINCT t.ticket_id) AS total_tickets_sold,
    SUM(t.price) AS total_revenue
FROM museum_schema.Exhibition e
JOIN museum_schema.Tickets t ON t.exhibition_id = e.exhibition_id
WHERE e.start_date >= (CURRENT_DATE - INTERVAL '3 months')
GROUP BY quarter, year;

SELECT * FROM recently_added_quarter_analytics;
	

-- Create a read-only role for the manager (SELECT, log in)

CREATE ROLE manager WITH LOGIN PASSWORD 'manager123';

GRANT USAGE ON SCHEMA museum_schema TO manager;
GRANT SELECT ON ALL TABLES IN SCHEMA museum_schema TO manager;

SET ROLE manager;

SELECT * FROM artifacts;