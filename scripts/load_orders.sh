#!/usr/bin/env bash
set -euo pipefail

# Load orders.csv into one warehouse (dev|prod).
# Usage: scripts/load_orders.sh <dev|prod> [csv_path]

ENV_NAME="${1:?usage: load_orders.sh <dev|prod> [csv]}"
CSV="${2:-$(cd "$(dirname "$0")/.." && pwd)/data/input/orders.csv}"
DB="etl_${ENV_NAME}"

case "$ENV_NAME" in
  dev|prod) ;;
  *) echo "env must be dev or prod" >&2; exit 1 ;;
esac

if [[ ! -f "$CSV" ]]; then
  echo "CSV not found: $CSV" >&2
  exit 1
fi

docker exec -i edp-postgres psql -U etl -d "$DB" <<'SQL'
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

docker exec -i edp-postgres psql -U etl -d "$DB" -c \
  "COPY raw.orders (order_id, customer_name, email, product, quantity, price, order_date)
   FROM STDIN WITH (FORMAT csv, HEADER true)" < "$CSV"

docker exec -i edp-postgres psql -U etl -d "$DB" -c \
  "UPDATE raw.orders SET _source_file = 'orders.csv' WHERE _source_file IS NULL"

COUNT="$(docker exec edp-postgres psql -U etl -d "$DB" -tAc 'SELECT count(*) FROM raw.orders')"
echo "Loaded ${COUNT} rows into ${DB}.raw.orders"
