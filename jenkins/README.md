# Jenkins CI/CD: DEV to PROD

This pipeline promotes **dbt model definitions and tests**, not raw data, Airflow
DAGs, Spark applications, or database backups. DEV and PROD have separate
PostgreSQL databases on the same homeserver; no STAGE environment is required.
The existing lab commands and lab dbt profile are unchanged.

## Build flow

1. Clean Jenkins workspace and check out `main`.
2. Check the agent and Docker, then resolve one immutable dbt image ID.
3. Check shell/Python syntax, run pytest and deployment-script checks.
4. Start an isolated PostgreSQL 17 container with synthetic employees/orders;
   run `dbt debug` and `dbt build`; remove that disposable stack even on failure.
5. If deployment is selected, run the same checked-out models/image in DEV.
6. If production promotion is selected, require distinct database names and build
   that same commit/image directly in PROD only after DEV succeeds.

`DEPLOY_DEV=false` and `DEPLOY_PROD=false` means CI only (including SCM-triggered
builds). `DEPLOY_DEV=true` adds DEV. `DEPLOY_PROD=true` implies DEV then PROD.
Production deployment is opt-in. Deployments must use the `main` checkout.
Polling checks for source changes every five minutes after the first build.

`dbt build` changes views/tables in `staging`, `intermediate`, and `mart`; it is
not an atomic transaction across an entire deployment. A failing dbt test blocks
the next environment but does not roll back already built objects. To redeploy
an older version, revert the relevant source commit on `main` and build again.

## Server prerequisites

- A connected Linux Jenkins agent labelled `platform-agent`; the existing node
  is named `homeserver-agent`. Keep the controller at zero executors.
- Git, Bash, Python 3 with `venv`/pip, GNU `timeout`, Docker and Compose v2 on
  that agent. Its account must access the Docker socket. The Docker daemon must
  be running, and the agent must be on this Docker host (not a container with
  unmapped workspace paths), because the pipeline bind-mounts its workspace.
- Internet access for GitHub, Python packages and container images.
- The agent can connect to both DEV and PROD PostgreSQL databases. Host
  networking defaults to this server; the credentials can also name remote hosts.

On this homeserver, Docker's data root is `/mnt/storage/docker` and the agent's
working directory is `/mnt/storage/jenkins-agent`. Confirm the storage disk is
mounted at `/mnt/storage` before starting either service; directories on the
root filesystem are not a replacement for that mount.

## Database credentials

Provision separate databases/roles such as `etl_dev`/`etl_dev` and
`etl_prod`/`etl_prod`. Both can share the existing PostgreSQL server; no separate
STAGE database or server is needed. Give each role access only to its own database, with
permission to create the model schemas, tables and views.

Both databases must already contain `raw.employees` and `raw.orders`, populated
by their own ingestion process. Their expected columns are in
[the dbt sources](../dbt/models/staging/_sources.yml). This pipeline never calls
the legacy truncating load scripts. The fixture SQL is for disposable CI only.

Complete copies of these templates outside Git:

- [DEV template](../environments/dev/jenkins.env.example)
- [PROD template](../environments/prod/jenkins.env.example)

Use plain unquoted `KEY=value` entries; passwords are literal values, not shell
expressions. Use different `DBT_DBNAME` values even if the databases are on
different servers. No credentials from the repository's lab `.env` are used.

In Jenkins, **Manage Jenkins → Credentials → System → Global credentials →
Add Credentials**, select **Secret file**, and upload each completed file:

| Credential ID | File |
| --- | --- |
| `edp-dev-env` | Completed DEV environment file |
| `edp-prod-env` | Completed PROD environment file |

Credentials are only needed for deployment, not CI-only builds. Do not commit
completed files, upload them as build artifacts, or paste passwords in logs.

## Publish and configure the job

If local and GitHub histories diverge, preserve both by reviewing/merging remote
`main`; do not force-push or discard local work.
Commit this pipeline and push the reconciled history to `main` before enabling
the job. Fetching the public repository uses HTTPS and needs no SSH passphrase;
pushing still requires your own authorized GitHub authentication.

The desired job configuration is [job.xml](job.xml): Pipeline from SCM,
public HTTPS repository, branch `*/main`, script `Jenkinsfile`, no SCM credential.
The job exposes `DEPLOY_DEV` and `DEPLOY_PROD`. Jenkins plugins used are Pipeline,
Git, Credentials Binding and JUnit (already installed on this controller).

Log in to Jenkins, generate an API token from your user profile, then run in
your own terminal (the token input is hidden):

```bash
export JENKINS_URL=http://127.0.0.1:8082
read -r -p 'Jenkins username: ' JENKINS_USER
read -r -s -p 'Jenkins API token: ' JENKINS_API_TOKEN; echo
export JENKINS_USER JENKINS_API_TOKEN
bash scripts/configure_jenkins.sh
unset JENKINS_API_TOKEN
```

The setup script refuses an unpublished/dirty checkout, validates the Jenkinsfile
with Jenkins, saves the existing job XML under ignored `artifacts/jenkins/`, and
updates/enables the job without triggering a build. API-token authentication does
not require a CSRF crumb. Alternatively apply the same fields in the Jenkins UI,
enable the job, and remove any obsolete `DEPLOY_STAGE` parameter manually.

Start with **Build with Parameters**, both deployment options unchecked. Once
CI succeeds and database credentials are configured, select `DEPLOY_PROD` to
run CI → DEV → PROD. Builds archive the commit/image IDs, dbt manifests/results,
and publish pytest results. Secrets and dbt logs are not archived.

## Run checks without Jenkins

```bash
bash tests/test_pipeline.sh                   # no Docker daemon needed
bash scripts/validate_dbt.sh                 # disposable CI database
bash scripts/deploy_dbt.sh check-isolation /secure/dev.env /secure/prod.env
bash scripts/deploy_dbt.sh dev /secure/dev.env
bash scripts/deploy_dbt.sh prod /secure/prod.env
```

The last two commands deploy database objects; they are not dry runs.

References: [Jenkins Pipeline syntax](https://www.jenkins.io/doc/book/pipeline/syntax/),
[credentials binding](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#handling-credentials),
[API-token authentication](https://www.jenkins.io/doc/book/security/csrf-protection/#working-with-scripted-clients).
