#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER $DATABASE_USERNAME with SUPERUSER PASSWORD '$DATABASE_PASSWORD';
    CREATE DATABASE ${DATABASE_NAME} OWNER $DATABASE_USERNAME;
EOSQL