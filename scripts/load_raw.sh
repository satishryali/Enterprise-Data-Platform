#!/usr/bin/env bash
set -euo pipefail

CSV="${1:-$(cd "$(dirname "$0")/.." && pwd)/data/input/employees.csv}"
CONTAINER="edp-postgres"

if [[ ! -f "$CSV" ]]; then
  echo "CSV not found: $CSV" >&2
  exit 1
fi

docker exec -i "$CONTAINER" psql -U etl -d etl <<'SQL'
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

docker exec -i "$CONTAINER" psql -U etl -d etl -c \
  "COPY raw.employees (employee_id, first_name, last_name, email, phone, department, salary, joining_date)
   FROM STDIN WITH (FORMAT csv, HEADER true)" < "$CSV"

docker exec -i "$CONTAINER" psql -U etl -d etl -c \
  "UPDATE raw.employees SET _source_file = 'employees.csv' WHERE _source_file IS NULL"

COUNT="$(docker exec "$CONTAINER" psql -U etl -d etl -tAc 'SELECT count(*) FROM raw.employees')"
echo "Loaded ${COUNT} rows into etl.raw.employees"
