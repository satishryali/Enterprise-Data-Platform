# Enterprise-Data-Platform

Single home-lab stack on one server: Postgres, Airflow, Oracle, dbt, Jenkins.

## Services

| Service | URL / port |
|---|---|
| Airflow | http://192.168.1.195:8081 (user `airflow`, password in `.env`) |
| Postgres | `192.168.1.195:5432`, database `etl`, user `etl` |
| Oracle | `192.168.1.195:1521`, service `FREEPDB1` |
| Jenkins | http://192.168.1.195:8082 |

## Commands

```bash
cd /home/satish/Enterprise-Data-Platform
scripts/lab.sh up
scripts/lab.sh status
scripts/lab.sh dbt
scripts/lab.sh down
```

Oracle only:

```bash
docker stop edp-oracle
docker start edp-oracle
```

Copy `.env.example` to `.env` on a new machine. Secrets are not in Git.
