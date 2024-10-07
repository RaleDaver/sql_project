SELECT * FROM staff;
SELECT * FROM store;
SELECT * FROM address;
SELECT * FROM payment;
SELECT * FROM rental;

DROP TABLE employee_performance_detailed_July_2005;
DROP TABLE employee_performance_summary_July_2005;
DROP FUNCTION add_dollar_sign(numeric);
DROP FUNCTION insert_trigger_function();
DROP TRIGGER update_summary_table;
DROP PROCEDURE refresh_all_tables;

--B.transformation
CREATE OR REPLACE FUNCTION add_dollar_sign(payment_amount NUMERIC(5,2))
RETURNS TEXT 
LANGUAGE plpgsql
AS $$
BEGIN
RETURN '$' || TO_CHAR(payment_amount, 'FM999.00');
END;
$$

--C.detailed table, summary table
CREATE TABLE employee_performance_detailed_July_2005 (
    staff_id            INT,
    staff_first_name    VARCHAR(20),
    staff_last_name     VARCHAR(20),
    store_location      VARCHAR(50),
    rental_id           INT,
    rental_date			TIMESTAMP,
	payment_amount      DECIMAL(5,2)
);

CREATE TABLE employee_performance_summary_July_2005 (
    staff_id            	INT,
    staff_first_name    	VARCHAR(20),
    staff_last_name     	VARCHAR(20),
	store_location			VARCHAR(50),
    total_transactions  	INT,
    total_revenue			DECIMAL(8,2),
	average_price			DECIMAL(4,2)
);

--D.extract raw data
INSERT INTO employee_performance_detailed_July_2005
SELECT s.staff_id, s.first_name, s.last_name, a.address, r.rental_id, r.rental_date, p.amount
FROM staff s
LEFT JOIN address a ON a.address_id=s.store_id
LEFT JOIN rental r ON s.staff_id=r.staff_id
LEFT JOIN payment p ON p.rental_id=r.rental_id
GROUP BY s.staff_id, a.address, r.rental_id, p.amount
HAVING rental_date BETWEEN '2005-07-01' AND '2005-07-31'
ORDER BY first_name DESC, rental_date DESC;

INSERT INTO employee_performance_summary_July_2005
SELECT staff_id, staff_first_name, staff_last_name, store_location, COUNT(rental_id) AS total_transactions, SUM(payment_amount) AS total_revenue, AVG(payment_amount) AS average_price
FROM employee_performance_detailed_July_2005
GROUP BY staff_id, staff_first_name, staff_last_name, store_location
ORDER BY staff_id;

--test to show created tables w/transformed field
SELECT staff_id, staff_first_name, staff_last_name, store_location, rental_id, rental_date, add_dollar_sign(payment_amount) AS payment_amount
FROM employee_performance_detailed_July_2005;
SELECT * FROM employee_performance_summary_July_2005;
	
--E.stored function to refresh the summary table when detailed table updated
CREATE OR REPLACE FUNCTION insert_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
DELETE FROM employee_performance_summary_July_2005;
INSERT INTO employee_performance_summary_July_2005
SELECT staff_id, staff_first_name, staff_last_name, store_location, COUNT(rental_id) AS total_transactions, SUM(payment_amount) AS total_revenue
FROM employee_performance_detailed_July_2005
GROUP BY staff_id, staff_first_name, staff_last_name, store_location
ORDER BY staff_id;
RETURN NEW;
END;
$$

CREATE TRIGGER update_summary_table
AFTER INSERT
ON employee_performance_detailed_July_2005
FOR EACH STATEMENT
EXECUTE PROCEDURE insert_trigger_function();

--trigger test
INSERT INTO employee_performance_detailed_July_2005
VALUES (1, 'Mike', 'Hillyer', '47 MySakila Drive', 9999, '2005-07-30 23:58:00', '8.99');

SELECT staff_id, staff_first_name, staff_last_name, store_location, rental_id, rental_date, add_dollar_sign(payment_amount) AS payment_amount
FROM employee_performance_detailed_July_2005 
ORDER BY staff_id, rental_id DESC;
SELECT * FROM employee_performance_summary_July_2005;

--F.stored procedure to refresh the detailed and summary table
CREATE OR REPLACE PROCEDURE refresh_all_tables()
LANGUAGE plpgsql
AS $$
BEGIN
DROP TABLE IF EXISTS employee_performance_detailed_July_2005;
DROP TABLE IF EXISTS employee_performance_summary_July_2005;

CREATE TABLE employee_performance_detailed_July_2005 (
    staff_id            INT,
    staff_first_name    VARCHAR(20),
    staff_last_name     VARCHAR(20),
    store_location      VARCHAR(50),
    rental_id           INT,
    rental_date			TIMESTAMP,
	payment_amount      DECIMAL(5,2)
);

CREATE TABLE employee_performance_summary_July_2005 (
    staff_id            	INT,
    staff_first_name    	VARCHAR(20),
    staff_last_name     	VARCHAR(20),
	store_location			VARCHAR(50),
    total_transactions  	INT,
    total_revenue			DECIMAL(8,2),
	average_price			DECIMAL(4,2)
);

INSERT INTO employee_performance_detailed_July_2005
SELECT s.staff_id, s.first_name, s.last_name, a.address, r.rental_id, r.rental_date, p.amount
FROM staff s
LEFT JOIN address a ON a.address_id=s.store_id
LEFT JOIN rental r ON s.staff_id=r.staff_id
LEFT JOIN payment p ON p.rental_id=r.rental_id
GROUP BY s.staff_id, a.address, r.rental_id, p.amount
HAVING rental_date BETWEEN '2005-07-01' AND '2005-07-31'
ORDER BY first_name DESC, rental_date DESC;

INSERT INTO employee_performance_summary_July_2005
SELECT staff_id, staff_first_name, staff_last_name, store_location, COUNT(rental_id) AS total_transactions, SUM(payment_amount) AS total_revenue, AVG(payment_amount) AS average_price
FROM employee_performance_detailed_July_2005
GROUP BY staff_id, staff_first_name, staff_last_name, store_location
ORDER BY staff_id;

RETURN;
END;
$$

CALL refresh_all_tables();

SELECT staff_id, staff_first_name, staff_last_name, store_location, rental_id, rental_date, add_dollar_sign(payment_amount) AS payment_amount
FROM employee_performance_detailed_July_2005;
SELECT * FROM employee_performance_summary_July_2005;