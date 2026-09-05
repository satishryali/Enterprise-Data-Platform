# Enterprise-Data-Platform

Home-lab enterprise-style data engineering platform for building and learning production-grade data pipelines.

## Architecture

`
Oracle / Source DB
        |
        v
Apache Airflow (Orchestration - DEV/STG/PROD)
        |
        v
PostgreSQL (per environment)
   |--- raw
   |--- staging
   |--- intermediate
   |--- mart
        |
        v
dbt Core (Transformations & Modeling)
        |
        v
Metabase / Jupyter (Analytics - on-demand)
`

## Tech Stack

- Apache Airflow - Workflow orchestration (DEV/STG/PROD environments)
- PostgreSQL - Data warehouse per environment (DEV, STG, PROD)
- dbt Core - Transformations and data modeling
- Jenkins - CI/CD automation
- Docker Compose - Container orchestration
- Vault - Secrets management
- Oracle - Source database (on-demand)
- Metabase / Jupyter - Analytics (on-demand)

## Repository Structure

`
Enterprise-Data-Platform/
|-- airflow/
|   |-- dags/
|   |-- plugins/
|   |-- config/
|-- dbt/
|   |-- models/
|   |   |-- staging/
|   |   |-- intermediate/
|   |   |-- marts/
|   |-- tests/
|   |-- macros/
|   |-- seeds/
|   |-- snapshots/
|-- postgres/
|   |-- dev/
|   |   |-- init/
|   |-- stg/
|   |   |-- init/
|   |-- prod/
|       |-- init/
|-- docker/
|   |-- airflow/
|   |-- dbt/
|   |-- postgres/
|-- environments/
|   |-- dev/
|   |-- stg/
|   |-- prod/
|-- jenkins/
|-- scripts/
|-- tests/
|-- data/
|   |-- input/
|   |-- output/
|   |-- sample/
|-- src/
|   |-- main.py
|   |-- csv_reader.py
|-- config/
|   |-- config.ini
|-- logs/
|-- requirements.txt
|-- .gitignore
|-- README.md
`

## Environment Strategy

| Environment | Purpose | Airflow | PostgreSQL | Notes |
|-------------|---------|---------|------------|-------|
| DEV | Development & testing | On-demand | Dedicated instance | Started/stopped as needed |
| STG | Staging & validation | On-demand | Dedicated instance | Started/stopped as needed |
| PROD | Production workload | Always running | Dedicated instance | Continuous operation |

## Resource Constraints (RAM)

> Total Docker RAM available: ~11.57 GiB
> Target total stack usage: ~5 GiB

| Service | RAM Target | Schedule |
|---------|-----------|----------|
| PROD Airflow | ~2 GiB | Always running |
| DEV/STG Airflow | ~1 GiB each | On-demand only |
| PostgreSQL (x3) | ~1.5 GiB | DEV/STG on-demand, PROD always |
| dbt | <500 MiB | On execution |
| Jenkins | ~1 GiB | On-demand |
| Vault | ~256 MiB | Always running |
| Oracle | ~2 GiB | On-demand only |
| Metabase / Jupyter | ~1 GiB | On-demand only |

## Design Principles

1. Modularity - Orchestration (Airflow) separated from transformation (dbt)
2. No business logic in DAGs - All transformation logic lives in dbt models
3. Multi-environment support - Isolated DEV/STG/PROD PostgreSQL instances
4. Resource efficiency - On-demand services stopped when not needed
5. No Redis - Avoided unless actually required
6. Security - Secrets stored in Vault; never committed to Git

## Status

> Skeleton only. No Docker configurations, DAGs, dbt models, or application code yet.
> Implementation roadmap to follow.
