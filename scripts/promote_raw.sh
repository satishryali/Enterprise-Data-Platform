#!/usr/bin/env bash
set -euo pipefail

# Copy raw.employees from one warehouse database to another (DEV -> STG -> PROD).
# Usage: scripts/promote_raw.sh <source_db> <dest_db>
# Example: scripts/promote_raw.sh etl_dev etl_stg

SRC="${1:?usage: promote_raw.sh <source_db> <dest_db>}"
DST="${2:?usage: promote_raw.sh <source_db> <dest_db>}"

docker exec edp-postgres psql -U postgres -d "$SRC" -c "SELECT 1 FROM raw.employees LIMIT 1" >/dev/null
docker exec edp-postgres psql -U postgres -d "$DST" -c "DROP TABLE IF EXISTS raw.employees"
docker exec edp-postgres bash -c "pg_dump -U postgres -d '$SRC' -t raw.employees --no-owner --no-privileges | psql -U postgres -d '$DST' -v ON_ERROR_STOP=1"
docker exec edp-postgres psql -U postgres -d "$DST" -c "ALTER TABLE raw.employees OWNER TO etl"
docker exec edp-postgres psql -U postgres -d "$DST" -c "GRANT ALL ON TABLE raw.employees TO etl"

COUNT="$(docker exec edp-postgres psql -U etl -d "$DST" -tAc 'SELECT count(*) FROM raw.employees')"
echo "Promoted raw.employees ${SRC} -> ${DST} (${COUNT} rows)"
