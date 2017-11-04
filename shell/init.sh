#!/usr/bin/env bash
/usr/local/hadoop/sbin/start-dfs.sh
/usr/local/hadoop/sbin/start-yarn.sh
service mysql start
hive -e "DROP DATABASE IF EXISTS bapi_test CASCADE"
hive -e "create database bapi_test"
hive -e "create table bapi_test.test1 (time_stamp INT, row_id INT, msg STRING) row format delimited  fields terminated by ',' stored as textfile;"


/store/replication/examples/mysql2hdfs/happlier --field-delimiter=, mysql://root@localhost hdfs://localhost:9000
