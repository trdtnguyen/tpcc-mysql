#!/bin/bash
source const.sh

sudo sysctl vm.drop_caches=3
sudo sysctl vm.drop_caches=3

statfile=$BENCHMARK_HOME/overall.txt

date=$(date '+%Y_%m_%d_%H_%M_%S')
#date="$(date --rfc-3339=seconds)"
#Get the buffer pool value
BUFFER_POOL=$($MYSQL -u vldb -e "SHOW VARIABLES LIKE '%buffer_pool_size%';" | grep "buffer_pool_size" | awk '{print($2/(1024^3))}')
echo "Current buffer pool size is $BUFFER_POOL GB"

outfile=$OUT_DIR/${date}_${METHOD}_W${WH}_BP${BUFFER_POOL}.out

#####################################
###### Pre-Benchmark ################
#####################################

if [ -n $1 ]; then
	METHOD=$1
fi

if [ $IS_INTEL_NVME -eq 1 ]; then
	echo "Collect Intel NVMe information"
	UNIT_READS1=$(sudo isdct show -intelssd 0 -performance | grep "DataUnitsRead" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	UNIT_WRITES1=$(sudo isdct show -intelssd 0 -performance | grep "DataUnitsWritten" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	HOST_READS1=$(sudo isdct show -intelssd 0 -performance | grep "HostReadCommands" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	HOST_WRITES1=$(sudo isdct show -intelssd 0 -performance | grep "HostWriteCommands" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	EREASE1=$(sudo isdct show -intelssd 0 -smart AD | grep "Raw" | awk -v FS="[():]" '{printf("%s\n",$2)}')
fi

######### TRACE UTIL ##############
kill -9 $(ps -opid= -C pmem_trace)
$BENCHMARK_HOME/pmem_trace.sh &
#########  ##############


#####################################
####### Run the benchmark #################
#####################################

#file format method_warehourses_bufferpool.out
echo "Run the tppc in $RUNTIME seconds..."
$TPCC_START -h$HOST -d$DBNAME -u$USER -w$WH -c$CONN -l$RUNTIME -i10 2>&1 | tee $outfile


#####################################
###### Post-Benchmark
#####################################

######### PART 1: Benchmark info
echo "======== the benchmark run is finished, start collect results..."
printf "${date} method=${METHOD} WH=${WH} BP=${BUFFER_POOL} " >> $statfile

# TPCC result
cat $outfile | grep trx | awk -v FS="[,():]" '{c=c+10;s=s+$3;lat=lat+$7;max_rt=max_rt+$9} END {c=(c/60);printf("TpmC=%s avg.99lat=%s max_rt=%s ",(s/c),(lat/c),(max_rt/c))}' >> $statfile

######### Part 2: Get the necessary values from "SHOW ENGINE INNODB STATUS \G #####
$MYSQL -u $USER -e "show engine innodb status \g" > dummy.txt &&
   	sed -i -e 's|\\n|\n|g' dummy.txt &&
	sudo cat dummy.txt | grep 'fsyncs' | awk -F' ' '{printf("%s ", $0)}' >> $statfile
   	rm dummy.txt

######## Part 3 Devices info


if [ $IS_INTEL_NVME -eq 1 ]; then
	UNIT_READS2=$(sudo isdct show -intelssd 0 -performance | grep "DataUnitsRead" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	UNIT_WRITES2=$(sudo isdct show -intelssd 0 -performance | grep "DataUnitsWritten" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	HOST_READS2=$(sudo isdct show -intelssd 0 -performance | grep "HostReadCommands" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	HOST_WRITES2=$(sudo isdct show -intelssd 0 -performance | grep "HostWriteCommands" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	EREASE2=$(sudo isdct show -intelssd 0 -smart AD | grep "Raw" | awk -v FS="[():]" '{printf("%s\n",$2)}')

	printf "DataUnitsRead = $(($UNIT_READS2-$UNIT_READS1)) " >> $statfile
	printf "DataUnitsWritten = $(($UNIT_WRITES2-$UNIT_WRITES1)) " >> $statfile
	printf "HostReadCommands = $(($HOST_READS2-$HOST_READS1)) " >> $statfile
	printf "HostWriteCommands = $(($HOST_WRITES2-$HOST_WRITES1)) " >> $statfile
	printf "WearLevelingCount = $(($EREASE2-$EREASE1)) " >> $statfile
fi
printf "\n" >> $statfile
##### End of line in file

echo "collecting results is finished, check $statfile for overall result and $outfile for detail result"

#kill it if it hasn't died yet
sudo kill -9 $(ps -opid= -C pmem_trace)
