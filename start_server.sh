#!/bin/bash

source const.sh

echo "Start mysqld ..."
$MYSQL_BIN/mysqld --defaults-file=$CONFIG -u $USER
