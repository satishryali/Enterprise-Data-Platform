select
    order_id,
    customer_name,
    email,
    product,
    quantity,
    price,
    order_date,
    round(quantity * price, 2) as line_total
from {{ ref('int_orders_clean') }}
