#!/usr/bin/env bash
set -euo pipefail

CSV="${1:-$(cd "$(dirname "$0")/.." && pwd)/data/input/orders.csv}"
CONTAINER="edp-postgres"

if [[ ! -f "$CSV" ]]; then
  echo "CSV not found: $CSV" >&2
  exit 1
fi

docker exec -i "$CONTAINER" psql -U etl -d etl <<'SQL'
CREATE TABLE IF NOT EXISTS raw.orders (
    order_id text,
    customer_name text,
    email text,
    product text,
    quantity text,
    price text,
    order_date text,
    _loaded_at timestamptz default now(),
    _source_file text
);
TRUNCATE TABLE raw.orders;
SQL

docker exec -i "$CONTAINER" psql -U etl -d etl -c \
  "COPY raw.orders (order_id, customer_name, email, product, quantity, price, order_date)
   FROM STDIN WITH (FORMAT csv, HEADER true)" < "$CSV"

docker exec -i "$CONTAINER" psql -U etl -d etl -c \
  "UPDATE raw.orders SET _source_file = 'orders.csv' WHERE _source_file IS NULL"

COUNT="$(docker exec "$CONTAINER" psql -U etl -d etl -tAc 'SELECT count(*) FROM raw.orders')"
echo "Loaded ${COUNT} rows into etl.raw.orders"
