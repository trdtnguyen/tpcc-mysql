#!/bin/bash

#usage: ./start_server [buffer_pool_size]
#buffer_pool_size: default/ommited 1

source const.sh

BPSIZE=5

if [ -n $1 ]; then
	BPSIZE=$1
fi

echo "Start mysqld with buffer pool size is $BPSIZE GB..."
$MYSQL_BIN/mysqld --defaults-file=$CONFIG -u $USER --innodb_buffer_pool_size=${BPSIZE}G
