#!/bin/bash

pg_ctl -D /var/lib/postgresql/data stop
# pgpass未生效，所以使用了export方式，还有可以在pg_hba.conf文件修改md5为trust，不建议这种方式
# 创建~/.pgpass文件为replica用户提供password 
# hostname:port:database:username:password
# touch ~/.pgpass
# chown postgres:postgres ~/.pgpass
# chmod 0600 ~/.pgpass
# echo "master:5432:replication:replica:replica" >> ~/.pgpass
# echo "slave:5432:replication:replica:replica" >> ~/.pgpass
# echo $(ls -al ~/.pgpass)
# echo $(whoami)
# echo $(cat ~/.pgpass)

rm -rf /var/lib/postgresql/data/*
# 需要提供replica用户的password
export PGPASSWORD="replica"
pg_basebackup -R -D /var/lib/postgresql/data -Fp -Xs -v -P -h master -p 5432 -U replica
# 删除密码
export -n PGPASSWORD="replica"

# touch /var/lib/postgresql/data/postmaster.pid
# 基础备份会自动生成standby.signal
# touch /var/lib/postgresql/data/standby.signal

cat >> /var/lib/postgresql/data/postgresql.conf << EOF
primary_conninfo = 'host=master port=5432 user=replica'
promote_trigger_file = '/tmp/replica_trigger/trigger_file'
recovery_target_timeline = 'latest'
hot_standby = on
listen_addresses = '*'
# pg12后不再使用standby.signal,而是建立空文件standby.signal进行触发
# standby_mode = on
EOF

pg_ctl -D /var/lib/postgresql/data start
echo "自定义执行完成"