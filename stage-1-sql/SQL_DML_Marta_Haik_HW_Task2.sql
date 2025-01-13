-- Task 2

-- 1. Create table ‘table_to_delete’ and fill it with the following query:
-- 2. Lookup how much space this table consumes with the following query:

575 MB

-- 3. Issue the following DELETE operation on ‘table_to_delete’
-- a) Note how much time it takes to perform this DELETE statement;

Query returned successfully in 18 secs 871 msec.


-- b) Lookup how much space this table consumes after previous DELETE;

looks like its the same space (575 MB)


-- c) Perform the following command (if youre using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)): 
-- VACUUM FULL VERBOSE table_to_delete
-- d) Check space consumption of the table once again and make conclusions

now it went from 575 MB to 383 MB


-- e) Recreate ‘table_to_delete’ table;
-- DROP TABLE IF EXISTS table_to_delete;
-- CREATE TABLE table_to_delete AS
-- SELECT veeeeeeery_long_string' || x AS col
-- FROM generate_series(1,(10^7)::int) x;

Query returned successfully in 26 secs 600 msec.


-- 4. Issue the following TRUNCATE operation:
--TRUNCATE table_to_delete;
-- a) Note how much time it takes to perform this TRUNCATE statement.

Query returned successfully in 1 secs 196 msec.


-- b) Compare with previous results and make conclusion.

TRUNCATE is stronger than DELETE


--c) Check space consumption of the table once again and make conclusions;

its 0 bytes now? I think its empty now



-- 5. Hand over your investigation's results to your trainer. The results must include:

-- a) Space consumption of ‘table_to_delete’ table before and after each operation;
-- b) Duration of each operation (DELETE, TRUNCATE)

