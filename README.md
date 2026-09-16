# Isolated DEV / PROD on one host. PROD is off until Jenkins deploys a Git commit.

## Isolation

| | DEV | PROD |
|---|---|---|
| Compose project | `edp-dev` | `edp-prod` |
| Docker network | `edp-dev_default` | `edp-prod_default` |
| Postgres | `edp-dev-postgres` :5432 | `edp-prod-postgres` :5433 (stopped by default) |
| Airflow | :8081 | not started |
| Oracle | `edp-dev-oracle` :1521 | none |
| Code | this git working tree | `/mnt/storage/import/edp-prod/release` (Jenkins rsync) |

There is no shared database, no `promote_raw` copy, and no shared Docker network. Objects reach PROD only from Git via Jenkins.

## Commands

```bash
scripts/lab.sh up          # DEV: Postgres + Airflow + Oracle
scripts/lab.sh status
scripts/lab.sh dbt-dev
scripts/lab.sh down

scripts/lab.sh prod-up     # optional, or let Jenkins start it
scripts/lab.sh dbt-prod
scripts/lab.sh prod-down   # PROD uses no RAM when down
```

Jenkins: **Build Now** = DEV only. Tick **DEPLOY_PROD** to rsync the commit and run dbt on PROD Postgres.

Oracle (DEV only): `192.168.1.195:1521` service `FREEPDB1`, user `sys` as SYSDBA. Stop Airflow if Oracle is killed (exit 137) — this host has 12 GB RAM.
