with staged as (
    select * from {{ ref('stg_employees') }}
),

typed as (
    select
        employee_id,
        first_name,
        last_name,
        email,
        phone,
        department,
        case
            when salary_raw ~ '^[0-9]+(\.[0-9]+)?$' then salary_raw::numeric
        end as salary,
        case
            when pg_input_is_valid(joining_date_raw, 'date')
                then joining_date_raw::date
        end as joining_date,
        _loaded_at,
        _source_file
    from staged
),

valid as (
    select *
    from typed
    where employee_id is not null
      and first_name is not null
      and email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
      and salary is not null
      and salary > 0
      and joining_date is not null
)

select distinct on (employee_id)
    employee_id,
    first_name,
    last_name,
    email,
    phone,
    department,
    salary,
    joining_date,
    _loaded_at,
    _source_file
from valid
order by employee_id, _loaded_at desc
