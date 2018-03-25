#!/bin/bash
source const.sh

sudo sysctl vm.drop_caches=3
sleep 2
sudo sysctl vm.drop_caches=3


query1="UPDATE performance_schema.setup_consumers SET enabled = 'YES' WHERE name like 'events_waits%';"

query2=" SELECT EVENT_NAME, COUNT_STAR, SUM_TIMER_WAIT/1000000000 SUM_TIMER_WAIT_MS 
		FROM performance_schema.events_waits_summary_global_by_event_name
		WHERE SUM_TIMER_WAIT > 0 AND EVENT_NAME LIKE 'wait/synch/mutex/innodb/%'
		ORDER BY SUM_TIMER_WAIT_MS DESC;
		"

#statfile=$BENCHMARK_HOME/overall.txt
#sumfile=$BENCHMARK_HOME/summary.txt

date=$(date '+%Y%m%d_%H%M%S')
#date="$(date --rfc-3339=seconds)"
#Get the buffer pool value
BUFFER_POOL=$($MYSQL -u vldb -e "SHOW VARIABLES LIKE '%buffer_pool_size%';" | grep "buffer_pool_size" | awk '{print($2/(1024^3))}')
echo "Current buffer pool size is $BUFFER_POOL GB"



#####################################
###### Pre-Benchmark ################
#####################################

if [ -n $1 ]; then
	METHOD=$1
	echo "param 1 is $1"
fi

if [ -n $2 ]; then
	CONN=$2
	echo "param 2 is $2"
fi

outfile=$OUT_DIR/${date}_${METHOD}_W${WH}_BP${BUFFER_POOL}_T${CONN}.out
outfile_mutex=$OUT_DIR/${date}_${METHOD}_W${WH}_BP${BUFFER_POOL}.mutex

if [ $IS_INTEL_NVME -eq 1 ]; then
	echo "Collect Intel NVMe information"
	UNIT_READS1=$(sudo isdct show -intelssd 0 -performance | grep "DataUnitsRead" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	UNIT_WRITES1=$(sudo isdct show -intelssd 0 -performance | grep "DataUnitsWritten" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	HOST_READS1=$(sudo isdct show -intelssd 0 -performance | grep "HostReadCommands" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	HOST_WRITES1=$(sudo isdct show -intelssd 0 -performance | grep "HostWriteCommands" | awk -v FS="[():]" '{printf("%d\n",$2)}')
	EREASE1=$(sudo isdct show -intelssd 0 -smart AD | grep "Raw" | awk -v FS="[():]" '{printf("%s\n",$2)}')
elif [ $IS_SAMSUNG_NVME -eq 1 ]; then
	echo "Collect Samsung NVMe information"
	UNIT_R1=$(sudo nvme smart-log $NVME_DEV1 | grep "data_units_read" | awk -v FS=" " '{printf("%s\n",$3)}'| sed 's/,//g')
	UNIT_W1=$(sudo nvme smart-log $NVME_DEV1 | grep "data_units_written" | awk -v FS=" " '{printf("%s\n",$3)}'| sed 's/,//g')
	HOST_R1=$(sudo nvme smart-log $NVME_DEV1 | grep "host_read_commands" | awk -v FS=" " '{printf("%s\n",$3)}'| sed 's/,//g')
	HOST_W1=$(sudo nvme smart-log $NVME_DEV1 | grep "host_write_commands" | awk -v FS=" " '{printf("%s\n",$3)}'| sed 's/,//g')
else
	#Samsung SSD
	ID241_1=$(sudo smartctl -a $SSD_DEV1 | grep "Total_LBAs_Written" | awk -v FS=" " '{printf("%s\n",$10)}')
	ID177_1=$(sudo smartctl -a $SSD_DEV1 | grep "Wear_Leveling_Count" | awk -v FS=" " '{printf("%s\n",$10)}')
fi

######### TRACE UTIL ##############
if [ $IS_TRACE -eq 1 ]; then
kill -9 $(ps -opid= -C pmem_trace)
$BENCHMARK_HOME/pmem_trace.sh &
fi
#########  ##############

######### PERFORMANCE SCHEMA ##############
#$MYSQL -u $USER -e "$query1"
#####################################

#####################################
####### Run the benchmark #################
#####################################

#file format method_warehourses_bufferpool.out
echo "Run the tppc in $RUNTIME seconds..."
$TPCC_START -h$HOST -d$DBNAME -u$USER -w$WH -c$CONN -l$RUNTIME -r$WARMUP_TIME -i10 2>&1 | tee $outfile


#####################################
###### Post-Benchmark
#####################################

######### PART 0: Mutex waits
#$MYSQL -u $USER -e "$query2" > $outfile_mutex


######### PART 1: Benchmark info
echo "======== the benchmark run is finished, start collect results..."
printf "${date} DES_DEVICE = ${DES_DEV} method = ${METHOD} WH = ${WH} CONN = ${CONN} RUNTIME = ${RUNTIME} BP = ${BUFFER_POOL} " >> $statfile

# TPCC result, 95% is $5, 99% is $7
cat $outfile | grep trx | awk -v FS="[,():]" '{c=c+10;s=s+$3;lat1=lat1+$5;lat2=lat2+$7;max_rt=max_rt+$9} END {c=(c/60);printf("TpmC = %s 95p = %s 99p = %s max_rt = %s ",(s/c),(lat1/c),(lat2/c),(max_rt/c))}' >> $statfile

######### Part 2: Get the necessary values from "SHOW ENGINE INNODB STATUS \G #####
$MYSQL -u $USER -e "show engine innodb status \g" > dummy.txt 
   	sed -i -e 's|\\n|\n|g' dummy.txt 
#Number of fsyncs
	sudo cat dummy.txt | grep 'fsyncs' | awk -F' ' '{printf("%s ", $0)}' >> $statfile
# semaphores
printf "Semaphores_OS_waits: " >> $statfile 
	sudo cat dummy.txt | grep 'OS waits' | awk -F' ' '{printf("%s ", $8)}' >> $statfile
#log io
	sudo cat dummy.txt | grep "log i/o's done" | awk -F' ' '{printf("%s ", $0)}' >> $statfile
	rm dummy.txt
#mutex
$MYSQL -u $USER -e "show engine innodb mutex" | grep sum | awk -v FS=" " '{printf("%s\n", $5)}' | awk -v FS="=" '{printf("sum_mutexes %s , ",$2)}' >> $statfile

#### InnoDB Buffer Pool Cache hit
# Get info for innodb buffer pool cache hit, cache_hit = val1 / (val1 + val2) * 100, val1 = reads_from_buf, val2=reads_from_dev
$MYSQL -u $USER -e "show global status like 'innodb_buffer_pool%';" | grep "read_requests" | awk '{printf(" reads_from_buf %s ",$2)}' >> $statfile
$MYSQL -u $USER -e "show global status like 'innodb_buffer_pool%';" | grep "reads" | awk '{printf("reads_from_dev %s ",$2)}' >> $statfile

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
elif [ $IS_SAMSUNG_NVME -eq 1 ]; then

	UNIT_R2=$(sudo nvme smart-log $NVME_DEV1 | grep "data_units_read" | awk -v FS=" " '{printf("%s\n",$3)}'| sed 's/,//g')
	UNIT_W2=$(sudo nvme smart-log $NVME_DEV1 | grep "data_units_written" | awk -v FS=" " '{printf("%s\n",$3)}'| sed 's/,//g')
	HOST_R2=$(sudo nvme smart-log $NVME_DEV1 | grep "host_read_commands" | awk -v FS=" " '{printf("%s\n",$3)}'| sed 's/,//g')
	HOST_W2=$(sudo nvme smart-log $NVME_DEV1 | grep "host_write_commands" | awk -v FS=" " '{printf("%s\n",$3)}'| sed 's/,//g')

	delta_unitw=$(($UNIT_W2-$UNIT_W1))
	delta_hostw=$(($HOST_W2-$HOST_W1))
	printf "DataUnitsRead = $(($UNIT_R2-$UNIT_R1)) " >> $statfile
	printf "DataUnitsWritten = $(($UNIT_W2-$UNIT_W1)) " >> $statfile
	printf "HostReadCommands = $(($HOST_R2-$HOST_R1)) " >> $statfile
	printf "HostWriteCommands = $(($HOST_W2-$HOST_W1)) " >> $statfile
else
	#Samsung SSD
	ID241_2=$(sudo smartctl -a $SSD_DEV1 | grep "Total_LBAs_Written" | awk -v FS=" " '{printf("%s\n",$10)}')
	ID177_2=$(sudo smartctl -a $SSD_DEV1 | grep "Wear_Leveling_Count" | awk -v FS=" " '{printf("%s\n",$10)}')

	d1=$(($ID241_2-$ID241_1))
	d2=$(($ID177_2-$ID177_1))
	tem1=$(($d1/(2*1024*1024)))	
	tem2=$(($d2*$SSD_SIZE))
	WAF=$(($tem2/$tem1))
	printf "Total_LBAs_Written = $d1 , Wear_Leveling_Count = $d2 , WAF = $WAF" >> $statfile

fi



printf "\n" >> $statfile
##### End of line in file

echo "collecting results is finished, check $statfile for overall result, $sumfile for summary, and $outfile for detail result"

#for summary info that can paste to excel file 
#printf "$date " >> $sumfile
#tail -n 1 $statfile | awk -v FS=" " '{printf("%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s\n",$6, $12, $21,$24, $27, $35, $39, $52, $53, $54, $55, $63, $66, $68, $71)}' >> $sumfile

if [ $IS_TRACE -eq 1 ]; then
#kill it if it hasn't died yet
sudo kill -9 $(ps -opid= -C pmem_trace)
fi
