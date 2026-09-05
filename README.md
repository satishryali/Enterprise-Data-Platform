# Enterprise-Data-Platform

Home-lab data engineering platform: one host, three logical environments (DEV / STG / PROD).

## Architecture

```
GitHub main  -->  Jenkins
                    |-- load CSV into etl_dev.raw  +  dbt --target dev
                    |-- copy raw DEV -> STG        +  dbt --target stg
                    `-- (optional) copy STG -> PROD +  dbt --target prod
```

Always-on: Postgres, Airflow, Vault, Jenkins, Prometheus/Grafana.
On-demand: Jupyter (`scripts/lab.sh jupyter`).

## Jenkins (DEV -> STG -> PROD)

Job: `Enterprise-Data-Platform` at http://192.168.1.195:8082

- Every build on `main` deploys **DEV**, then promotes **STG**.
- Check **DEPLOY_PROD** and approve the prompt to promote **PROD**.

Airflow UI (optional manual ingest): http://192.168.1.195:8081

## Local commands

```bash
scripts/lab.sh up
scripts/lab.sh dbt-dev
scripts/lab.sh jupyter
scripts/lab.sh down
```

## Resource notes

This i3-2100 / 12 GB host cannot run three Airflow clusters. Isolation is by database and dbt target, not by duplicating the stack.
