#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "postgres" <<-EOSQL
	CREATE DATABASE dbtirtha;
        CREATE USER dbtirthauser WITH PASSWORD 'docker';
        ALTER ROLE dbtirthauser SET client_encoding TO 'utf8';
        ALTER ROLE dbtirthauser SET default_transaction_isolation TO 'read committed';
        ALTER ROLE dbtirthauser SET timezone TO 'UTC';
        ALTER DATABASE dbtirtha OWNER TO dbtirthauser;
        GRANT ALL PRIVILEGES ON DATABASE dbtirtha TO dbtirthauser;
        GRANT CREATE ON SCHEMA public TO dbtirthauser;
EOSQL