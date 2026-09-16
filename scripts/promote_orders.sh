#!/usr/bin/env bash
set -euo pipefail

# Copy raw.orders from one warehouse database to another (DEV -> PROD).
# Usage: scripts/promote_orders.sh <source_db> <dest_db>
# Example: scripts/promote_orders.sh etl_dev etl_prod

SRC="${1:?usage: promote_orders.sh <source_db> <dest_db>}"
DST="${2:?usage: promote_orders.sh <source_db> <dest_db>}"

docker exec edp-postgres psql -U postgres -d "$SRC" -c "SELECT 1 FROM raw.orders LIMIT 1" >/dev/null
docker exec edp-postgres psql -U postgres -d "$DST" -c "DROP TABLE IF EXISTS raw.orders"
docker exec edp-postgres bash -c "pg_dump -U postgres -d '$SRC' -t raw.orders --no-owner --no-privileges | psql -U postgres -d '$DST' -v ON_ERROR_STOP=1"
docker exec edp-postgres psql -U postgres -d "$DST" -c "ALTER TABLE raw.orders OWNER TO etl"
docker exec edp-postgres psql -U postgres -d "$DST" -c "GRANT ALL ON TABLE raw.orders TO etl"

COUNT="$(docker exec edp-postgres psql -U etl -d "$DST" -tAc 'SELECT count(*) FROM raw.orders')"
echo "Promoted raw.orders ${SRC} -> ${DST} (${COUNT} rows)"
