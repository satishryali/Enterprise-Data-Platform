# Local credentials

The checked-in `.env.example` deliberately leaves passwords, the Fernet key, and
the JWT secret empty. Copy it to `.env` and fill them locally before starting the
platform. The current server's `.env` has not been changed.

For a fresh installation, generate a Fernet key with Python's cryptography package:

```bash
python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'
```

Keep the existing Fernet key when restoring Airflow metadata: it is needed to
decrypt stored connections. Back it up securely with the other credentials.

Git excludes local environment files, private keys, generated Spark tokens and
kubeconfig credentials. Public CA certificates do not contain private keys.

An Oracle password matching the server's `.env` exists in earlier Git commits.
Removing it from the current files does not remove it from history. Rotate the
exposed credential using the database's supported password change procedure and
update the local `.env` and dependent clients together. Merely editing `.env`
does not change an existing database user's password.

No history has been rewritten and no database passwords have been changed by
this cleanup. Removing secrets from existing history requires a separate,
coordinated cleanup across affected branches, remote copies, and clones.
