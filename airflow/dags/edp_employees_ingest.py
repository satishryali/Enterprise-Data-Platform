from datetime import datetime
from pathlib import Path

from airflow.sdk import dag, get_current_context, task
from airflow.providers.postgres.hooks.postgres import PostgresHook

DATA_FILE = Path("/opt/airflow/data/input/employees.csv")
CONN_BY_ENV = {
    "dev": "edp_dev",
    "stg": "edp_stg",
    "prod": "edp_prod",
}


@dag(
    dag_id="edp_employees_ingest",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["edp", "ingest"],
    params={"env": "dev"},
    doc_md=(
        "Load employees.csv into raw.employees for the chosen env "
        "(dev|stg|prod). Transform with dbt / Jenkins after ingest."
    ),
)
def edp_employees_ingest():
    @task
    def load_raw() -> str:
        env = str(get_current_context()["params"].get("env", "dev")).lower()
        if env not in CONN_BY_ENV:
            raise ValueError(f"env must be one of {sorted(CONN_BY_ENV)}, got {env}")
        if not DATA_FILE.exists():
            raise FileNotFoundError(DATA_FILE)

        hook = PostgresHook(postgres_conn_id=CONN_BY_ENV[env])
        hook.run(
            """
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
            )
            """
        )
        hook.run("TRUNCATE TABLE raw.employees")
        hook.copy_expert(
            """
            COPY raw.employees (
                employee_id, first_name, last_name, email, phone,
                department, salary, joining_date
            )
            FROM STDIN WITH (FORMAT csv, HEADER true)
            """,
            str(DATA_FILE),
        )
        hook.run(
            "UPDATE raw.employees SET _source_file = %s WHERE _source_file IS NULL",
            parameters=(DATA_FILE.name,),
        )
        count = hook.get_first("SELECT count(*) FROM raw.employees")[0]
        return f"Loaded {count} rows into {CONN_BY_ENV[env]}"

    load_raw()


edp_employees_ingest()
