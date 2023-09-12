#!/bin/bash

cat >> /var/lib/postgresql/data/postgresql.conf << EOF
wal_level = 'replica'
archive_mode = on
# 归档目录wal文件不存在则从wal目录拷贝到归档目录
archive_command = 'test ! -f /var/lib/postgresql/archive/%f && cp %p /var/lib/postgresql/archive/%f'
# 新版pg使用wal_keep_size代替wal_keep_segments
# wal_keep_size=wal_keep_segments*wal_segment_size (通常为16MB)
# wal_keep_segments = 64
wal_keep_size = 1024
listen_addresses = '*'
EOF

# 为slave节点基本备份设置访问用户和访问控制
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER replica with login replication password 'replica';
EOSQL

echo "host replication replica all md5" >> /var/lib/postgresql/data/pg_hba.conf

pg_ctl -D /var/lib/postgresql/data restart

echo "自定义配置执行完成"