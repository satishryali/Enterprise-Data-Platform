#!/usr/bin/env bash
set -euo pipefail

# Load employees.csv from Git into one warehouse (dev|stg|prod).
# Usage: scripts/load_raw.sh <dev|stg|prod> [csv_path]

ENV_NAME="${1:?usage: load_raw.sh <dev|stg|prod> [csv]}"
CSV="${2:-$(cd "$(dirname "$0")/.." && pwd)/data/input/employees.csv}"
DB="etl_${ENV_NAME}"

case "$ENV_NAME" in
  dev|stg|prod) ;;
  *) echo "env must be dev, stg, or prod" >&2; exit 1 ;;
esac

if [[ ! -f "$CSV" ]]; then
  echo "CSV not found: $CSV" >&2
  exit 1
fi

docker exec -i edp-postgres psql -U etl -d "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS raw.employees (
    employee_id text,
    first_name text,
    last_name text,
    email text,
    phone text,
    department text,
    salary text,
    joining_date text,
    _loaded_at timestamptz default now(),
    _source_file text
);
TRUNCATE TABLE raw.employees;
SQL

docker exec -i edp-postgres psql -U etl -d "$DB" -c \
  "COPY raw.employees (employee_id, first_name, last_name, email, phone, department, salary, joining_date)
   FROM STDIN WITH (FORMAT csv, HEADER true)" < "$CSV"

docker exec -i edp-postgres psql -U etl -d "$DB" -c \
  "UPDATE raw.employees SET _source_file = 'employees.csv' WHERE _source_file IS NULL"

COUNT="$(docker exec edp-postgres psql -U etl -d "$DB" -tAc 'SELECT count(*) FROM raw.employees')"
echo "Loaded ${COUNT} rows into ${DB}.raw.employees"
