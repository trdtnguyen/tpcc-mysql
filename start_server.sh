#!/bin/bash

#usage: ./start_server [buffer_pool_size]
#buffer_pool_size: default/ommited 1

source const.sh

BPSIZE=5

if [ -n $1 ]; then
	BPSIZE=$1
fi


#if [ $IS_USE_DBW -eq 1 ]; then
#echo "Start mysqld with buffer pool size is $BPSIZE GB, DBW is enable..."
#$MYSQL_BIN/mysqld --defaults-file=$CONFIG -u $USER --innodb_buffer_pool_size=${BPSIZE}G 
#$MYSQL_BIN/mysqld --defaults-file=$CONFIG -u $USER --innodb_buffer_pool_size=${BPSIZE}G &
#$MYSQL_BIN/mysqld --defaults-file=$CONFIG -u $USER --innodb_buffer_pool_size=${BPSIZE}G --debug
#else
#echo "Start mysqld with buffer pool size is $BPSIZE GB, DBW is disable..."
#$MYSQL_BIN/mysqld --defaults-file=$CONFIG -u $USER --innodb_buffer_pool_size=${BPSIZE}G  --skip-innodb_doublewrite
#fi

echo "Start mysqld with buffer pool size is $BPSIZE GB "
$MYSQL_BIN/mysqld --defaults-file=$CONFIG -u $USER --innodb_buffer_pool_size=${BPSIZE}G
