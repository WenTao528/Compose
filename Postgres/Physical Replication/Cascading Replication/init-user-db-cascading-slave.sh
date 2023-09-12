#!/bin/bash

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER replica with login replication password 'replica';
EOSQL

pg_ctl -D /var/lib/postgresql/data stop

rm -rf /var/lib/postgresql/data/*
# 需要提供replica用户的password
export PGPASSWORD="replica"
pg_basebackup -R -D /var/lib/postgresql/data -Fp -Xs -v -P -h primary -p 5432 -U replica
# 删除密码
export -n PGPASSWORD="replica"


cat >> /var/lib/postgresql/data/postgresql.conf << EOF
primary_conninfo = 'host=master port=5432 user=replica'
wal_level = 'replica'
max_wal_senders = 3
wal_keep_size = 1024
recovery_target_timeline = 'latest'
hot_standby = on
listen_addresses = '*'
EOF

pg_ctl -D /var/lib/postgresql/data start
echo "自定义配置完成"