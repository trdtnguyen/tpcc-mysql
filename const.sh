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

#Disable DBW for UNIV_PMEMOBJ_BUF
IS_USE_DBW=0

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

TRACE_FILE=trace.txt
PMEM_TRACE=pmem_trace.sh

#METHOD: ori, pmemblk, pmemmem, pmemlogbuf, pmemlogall
METHOD=pmembuf_40th
#METHOD=pmemblk
#METHOD=pmembuf
#WH=1000
WH=100
#WH=100
#CONN=24
CONN=48
#RUNTIME=7200
#RUNTIME=3600
RUNTIME=600
BP=60
