#!/bin/bash

METHOD=wal_850

# for reset_debug.sh
PMEM_DIR=/mnt/pmem1
SRC_DIR=/mnt/nvme1
DES_DIR=/mnt/ssd1
#DES_DIR=/mnt/nvme1

IS_INTEL_NVME=0
IS_SAMSUNG_NVME=0

#DATA_DIR=tpcc_w100_4k
#WH=100

#DATA_DIR=tpcc_w300_16k
DATA_DIR=tpcc_w300_4k
WH=300

#DATA_DIR=tpcc_w1000_4k
#WH=1000


#Those values for using nvme, smartctl
NVME_DEV1=/dev/nvme0n1
SSD_DEV1=/dev/sdd1

DEV1=$SSD_DEV1


#sleep time (in seconds)  may diffenrent depend on the data size
SLEEP_DROP_CACHE=2
SLEEP_CP=90 #small_data: 60, large_data: 120
#SLEEP_CP=120 #small_data: 60, large_data: 120
SLEEP_DB_LOAD=30 #sleep time between start server finish and run benchmark
SLEEP_BETWEEN_BM=60 #sleep time between benchmarks

#change this value according to the number of warehouse in the dataset 
CONN=32
#CONN=50
#CONN=100
#RUNTIME=1800
RUNTIME=900
#RUNTIME=100
SSD_SIZE=512 #GB

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

IS_TRACE=0
#IS_TRACE=1

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
#METHOD=pmemblk
#METHOD=pmembuf
#WH=1000
#WH=300
#CONN=24
#RUNTIME=7200
#RUNTIME=600
BP=60
