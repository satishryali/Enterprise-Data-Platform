select
    employee_id,
    first_name,
    last_name,
    email,
    phone,
    department,
    salary,
    joining_date
from {{ ref('int_employees_clean') }}
