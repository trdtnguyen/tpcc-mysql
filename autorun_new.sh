# !/bin/bash
#usage: ./autorun.sh
source const.sh

#cache_arr=(256 512 1024 2048 3072 4096 5120 10240)
#thread_arr=(8 16 32 64 128)

#Change those arrays based on your experiment purpose
#######################################################
cache_arr=(256 512 1024 2048 3072)
thread_arr=(64 64 64 64 64)
pm_buf_arr=(64 128 256 256 256)
pm_n_bucket_arr=(32 32 64 64 64)
pm_bucket_size_arr=(256 512 512 512 512)
pm_flush_threshold_arr=(1 1 5 15 15)
#####################################################

echo "cache_arr[@] = $cache_arr[@]"

#for i in {0..4}; do
for i in {3..4}; do
	printf 'ele %s is %s\n' "$i" "${thread_arr[i]}"
	echo "========  Buffer pool = ${cache_arr[i]} MB, threads = ${thread_arr[i]} ============" 

# (1) Reset the data
	$BENCHMARK_HOME/reset_debug.sh		

	echo "sleep $SLEEP_CP seconds after cp..."
	sleep $SLEEP_CP

# (2) Start the mysqld server
if [ $IS_PMEM_APP -eq 1 ]; then
	$BENCHMARK_HOME/start_server.sh ${cache_arr[i]} ${pm_buf_arr[i]} ${pm_n_bucket_arr[i]} ${pm_bucket_size_arr[i]} ${pm_flush_threshold_arr[i]} &
else
	$BENCHMARK_HOME/start_server.sh ${cache_arr[i]} &
fi

	echo "sleep $SLEEP_DB_LOAD seconds before run the benchmark..."
	sleep $SLEEP_DB_LOAD 

# (3) Run the TPC-C benchmark
	if [ $IS_PMEM_APP -eq 1 ]; then
		#name of method follow the format method_cachesize_pmemsize_warehouse
		$BENCHMARK_HOME/run.sh ${METHOD}_${cache_arr[i]}_${pm_buf_arr[i]}_${WH} ${thread_arr[i]}
	else
		$BENCHMARK_HOME/run.sh ${METHOD}_${cache_arr[i]}_NA_${WH} ${thread_arr[i]}
	fi

# (4) Stop the server
	#====>> finish benchmark
	$BENCHMARK_HOME/stop_server.sh
	sleep 5 

# (5) Collect final result
	printf "\n" >> $sumfile

date=$(date '+%Y%m%d_%H%M%S')
	printf "$date " >> $sumfile
	tail -n 1 $statfile | awk -v FS=" " '{printf("%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s ",$6, $12, $21,$24, $27, $35, $39, $52, $53, $54, $55, $63, $66, $68, $71)}' >> $sumfile

	#get total time for waiting flush from buffer pool to disk/nvm
	tail -n 1 $TRACE_FILE1 | awk '{printf("%s ", $7)}' >> $sumfile

	if [ $IS_PMEM_APP -eq 1 ]; then
		#get statistic information for PMEM
		tail -n 1 $TRACE_FILE2 >> $sumfile
	fi


	echo "====== finish run for buffer pool $cache GB, #threads=$thread, take some rest for $SLEEP_BETWEEN_BM seconds ===="
	sleep $SLEEP_BETWEEN_BM 

	# Next loop
done
