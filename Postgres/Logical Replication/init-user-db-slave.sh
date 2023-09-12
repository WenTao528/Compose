#!/bin/bash

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER replica with login replication password 'replica';
  CREATE TABLE weather (
    city            varchar(80),
    temp_lo         int,           -- 最低温度
    temp_hi         int,           -- 最高温度
    prcp            real,          -- 湿度
    date            date
  );
  CREATE SUBSCRIPTION mysub CONNECTION 'dbname=postgres host=master user=replica password=replica' PUBLICATION mypub;
EOSQL


cat >> /var/lib/postgresql/data/postgresql.conf << EOF
max_replication_slots = 3
max_logical_replication_workers = 3
max_worker_processes = 4
hot_standby = on
listen_addresses = '*'
EOF

pg_ctl -D /var/lib/postgresql/data restart
echo "自定义执行完成"