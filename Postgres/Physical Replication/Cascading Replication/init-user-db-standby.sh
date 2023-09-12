#!/bin/bash

pg_ctl -D /var/lib/postgresql/data stop

rm -rf /var/lib/postgresql/data/*
# 需要提供replica用户的password
export PGPASSWORD="replica"
pg_basebackup -R -D /var/lib/postgresql/data -Fp -Xs -v -P -h cascading-standby -p 5432 -U replica
# 删除密码
export -n PGPASSWORD="replica"

cat >> /var/lib/postgresql/data/postgresql.conf << EOF
primary_conninfo = 'host=master port=5432 user=replica'
recovery_target_timeline = 'latest'
hot_standby = on
listen_addresses = '*'
EOF

pg_ctl -D /var/lib/postgresql/data start
echo "自定义配置完成"