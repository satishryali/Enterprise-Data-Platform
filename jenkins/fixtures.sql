-- Synthetic CI data only; never loaded into DEV or PROD.
CREATE SCHEMA raw;
CREATE TABLE raw.employees (
    employee_id text, first_name text, last_name text, email text,
    phone text, department text, salary text, joining_date text,
    _loaded_at timestamptz DEFAULT now(), _source_file text
);
INSERT INTO raw.employees
    (employee_id, first_name, last_name, email, department, salary, joining_date)
VALUES ('1', 'CI', 'Employee', 'employee@example.test', 'Engineering', '50000', '2025-01-01');

CREATE TABLE raw.orders (
    order_id text, customer_name text, email text, product text,
    quantity text, price text, order_date text,
    _loaded_at timestamptz DEFAULT now(), _source_file text
);
INSERT INTO raw.orders
    (order_id, customer_name, email, product, quantity, price, order_date)
VALUES ('1', 'CI Customer', 'customer@example.test', 'Example product', '2', '10', '2025-01-02');
