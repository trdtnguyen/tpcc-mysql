#!/bin/bash
source const.sh

sudo sysctl vm.drop_caches=3
sudo sysctl vm.drop_caches=3

#if [ -n $1 ]; then
#	OUT_DIR=$1
#fi
#Get the buffer pool value

BUFFER_POOL=$(mysql -u vldb -e "SHOW VARIABLES LIKE '%buffer_pool_size%';" | grep "buffer_pool_size" | awk '{print($2/(1024^3))}')
echo "Current buffer pool size is $BUFFER_POOL GB"

#file format method_warehourses_bufferpool.out
echo "Run the tppc in $RUNTIME seconds..."
$TPCC_START -h$HOST -d$DBNAME -u$USER -w$WH -c$CONN -l$RUNTIME -i10 2>&1 | tee $OUT_DIR/${METHOD}_W${WH}_BP${BUFFER_POOL}.out
