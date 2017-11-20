#!/bin/bash

source const.sh

echo "Start mysqld_safe ..."
$MYSQL_BIN/mysqld_safe -u $USER
