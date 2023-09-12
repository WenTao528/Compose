#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER haproxy with password 'haproxy';
EOSQL
echo "host all haproxy all md5" >> /var/lib/postgresql/data/pg_hba.conf