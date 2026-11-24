# Enterprise-Data-Platform

Single home-lab stack on one server: Postgres, Airflow, Oracle, dbt, Jenkins.

## Jenkins CI/CD

[DEV-to-PROD pipeline setup](jenkins/README.md): isolated dbt integration tests,
optional DEV deployment, and same-commit promotion directly to PROD with separate credentials.
The pipeline promotes dbt objects, not raw data. No STAGE environment is required.

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
scripts/lab.sh dbt          # debug + full build
scripts/dbt.sh build        # any dbt command in Docker
scripts/dbt.sh debug
scripts/dbt.sh test
scripts/lab.sh pull-dbt     # download dbt image
scripts/lab.sh down
```

Oracle only:

```bash
docker stop edp-oracle
docker start edp-oracle
```

Copy `.env.example` to `.env` on a new machine and fill every password and key before `scripts/lab.sh up`. Generate a Fernet key and a strong JWT secret locally. URL-encode database passwords used in connection URLs (or use long random URL-safe passwords). `.env` and its local variants are ignored by Git; `.env.example` contains no credentials.

Keep generated credentials outside Git. See [SECRETS.md](SECRETS.md) for
credential handling and the existing history exposure, and
[SECRETS_SETUP.md](SECRETS_SETUP.md) for local setup.
