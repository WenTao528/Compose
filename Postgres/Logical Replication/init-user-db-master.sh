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
  GRANT SELECT,INSERT,UPDATE,DELETE ON weather TO replica;
  CREATE PUBLICATION mypub FOR TABLE weather;
EOSQL

cat >> /var/lib/postgresql/data/postgresql.conf << EOF
wal_level = 'logical'
max_wal_senders = 3
max_replication_slots = 3
wal_keep_size = 1024
listen_addresses = '*'
hot_standby = on
EOF

echo "host replication replica all md5" >> /var/lib/postgresql/data/pg_hba.conf

pg_ctl -D /var/lib/postgresql/data restart
echo "自定义配置执行完成"