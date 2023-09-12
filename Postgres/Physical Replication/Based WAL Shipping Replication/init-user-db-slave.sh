#!/bin/bash

pg_ctl -D /var/lib/postgresql/data stop

rm -rf /var/lib/postgresql/data/*
# 从主节点生成基本备份
# 需要提供replica用户的password
export PGPASSWORD="replica"
pg_basebackup -R -D /var/lib/postgresql/data -Fp -Xs -v -P -h master -p 5432 -U replica
# 删除密码
export -n PGPASSWORD="replica"

# 基础备份会自动生成standby.signal
# touch /var/lib/postgresql/data/standby.signal

cat >> /var/lib/postgresql/data/postgresql.conf << EOF
restore_command = 'cp /var/lib/postgresql/archive/%f %p'
archive_cleanup_command = 'pg_archivecleanup /var/lib/postgresql/archive %r'
recovery_target_timeline = 'latest'
# 新版pg standby_mode已被移除,使用standby.signal文件代替
# standby_mode = on
listen_addresses = '*'
EOF

pg_ctl -D /var/lib/postgresql/data start

echo "自定义配置执行完成"