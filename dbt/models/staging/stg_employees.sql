with src as (
    select * from {{ source('raw', 'employees') }}
)

select
    employee_id::varchar as employee_id,
    trim(first_name) as first_name,
    trim(last_name) as last_name,
    lower(trim(email)) as email,
    trim(phone) as phone,
    initcap(trim(department)) as department,
    nullif(trim(salary::varchar), '') as salary_raw,
    nullif(trim(joining_date::varchar), '') as joining_date_raw,
    _loaded_at,
    _source_file
from src
where coalesce(trim(employee_id::varchar), '') <> ''
