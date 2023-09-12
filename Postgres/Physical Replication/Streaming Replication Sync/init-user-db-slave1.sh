#!/bin/bash

pg_ctl -D /var/lib/postgresql/data stop -mf

rm -rf /var/lib/postgresql/data/*
# 需要提供replica用户的password
export PGPASSWORD="replica"
pg_basebackup -R -D /var/lib/postgresql/data -Fp -Xs -v -P -h master -p 5432 -U replica
# 删除密码
export -n PGPASSWORD="replica"

# primary_conninfo中的application_name=slave1 fallback_application_name=slave1未生效
# 因为在postgresql.auto.conf中有自动生成的primary_conninfo配置，里面没有application_name配置，
# 而postgresql.auto.conf文件的优先级高于postgresql.conf文件
cat >> /var/lib/postgresql/data/postgresql.conf << EOF
primary_conninfo = 'host=master port=5432 user=replica application_name=slave1 fallback_application_name=slave1'
recovery_target_timeline = 'latest'
hot_standby = on
listen_addresses = '*'
EOF

pg_ctl -D /var/lib/postgresql/data start

# 运行时重新修改primary_conninfo 并重启
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	ALTER SYSTEM SET primary_conninfo = 'application_name=slave1 user=replica password=replica channel_binding=prefer host=master port=5432 sslmode=prefer sslcompression=0 sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres target_session_attrs=any'; 
EOSQL

pg_ctl -D /var/lib/postgresql/data restart

echo "自定义配置执行完成"