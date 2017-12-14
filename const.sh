#!/bin/bash
BENCHMARK_HOME=/home/vldb/benchmark/tpcc-mysql
MYSQL_HOME=/usr/local/mysql
MYSQL_BIN=$MYSQL_HOME/bin
HOST=115.145.173.195
#HOST=localhost
PORT=3306
USER=vldb
DBNAME=tpcc
PASS=""

IS_RESET=0
IS_INTEL_NVME=1

#CONFIG=$BENCHMARK_HOME/my.cnf
CONFIG=/etc/my.cnf
#EXECUTES
MYSQL=$MYSQL_HOME/bin/mysql
TPCCLOAD=$BENCHMARK_HOME/tpcc_load
TABLESQL=$BENCHMARK_HOME/create_table.sql
CONSTRAINTSQL=$BENCHMARK_HOME/add_fkey_idx.sql
TPCC_LOAD=$BENCHMARK_HOME/tpcc_load
TPCC_START=$BENCHMARK_HOME/tpcc_start

OUT_DIR=$BENCHMARK_HOME/output

#METHOD: ori, pmemblk, pmemmem, pmemlogbuf, pmemlogall
#METHOD=ori
#METHOD=pmemblk
METHOD=pmemredolog
WH=1000
CONN=24
RUNTIME=7200
BP=60
