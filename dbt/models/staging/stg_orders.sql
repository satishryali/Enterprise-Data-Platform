with src as (
    select * from {{ source('raw', 'orders') }}
)

select
    order_id::varchar as order_id,
    trim(customer_name) as customer_name,
    lower(trim(email)) as email,
    trim(product) as product,
    nullif(trim(quantity::varchar), '') as quantity_raw,
    nullif(trim(price::varchar), '') as price_raw,
    nullif(trim(order_date::varchar), '') as order_date_raw,
    _loaded_at,
    _source_file
from src
where coalesce(trim(order_id::varchar), '') <> ''
