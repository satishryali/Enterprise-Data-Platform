with staged as (
    select * from {{ ref('stg_orders') }}
),

typed as (
    select
        order_id,
        customer_name,
        email,
        product,
        case
            when quantity_raw ~ '^-?[0-9]+(\.[0-9]+)?$' then quantity_raw::numeric
        end as quantity,
        case
            when price_raw ~ '^[0-9]+(\.[0-9]+)?$' then price_raw::numeric
        end as price,
        case
            when pg_input_is_valid(order_date_raw, 'date')
                then order_date_raw::date
        end as order_date,
        _loaded_at,
        _source_file
    from staged
),

valid as (
    select *
    from typed
    where order_id is not null
      and customer_name is not null
      and email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
      and product is not null
      and quantity is not null
      and quantity > 0
      and price is not null
      and price > 0
      and order_date is not null
)

select distinct on (order_id)
    order_id,
    customer_name,
    email,
    product,
    quantity,
    price,
    order_date,
    _loaded_at,
    _source_file
from valid
order by order_id, _loaded_at desc
