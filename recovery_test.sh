# !/bin/bash
#usage: ./autorun.sh
source const.sh

#cache_arr=(3)
cache_arr=(30)
thread_arr=(64)

echo "cache_arr[@] = $cache_arr[@]"

for cache in "${cache_arr[@]}"; do
echo "========  Buffer pool = $cache GB ============" 
	for thread in "${thread_arr[@]}"; do
		echo "========  Number of client threads = $thread ============" 

		#reset_debug.sh can be used seperatly or embedded
		#$BENCHMARK_HOME/reset_debug.sh		
		#echo "sleep $SLEEP_CP seconds after cp..."
		#sleep $SLEEP_CP

		$BENCHMARK_HOME/start_server.sh $cache &
		echo "sleep $SLEEP_DB_LOAD seconds before run the benchmark..."
		#for large innodb_log_file_size we need to sleep more 
		sleep 60 
		
		#set the thread killer that will kill processes after a period of time
		$BENCHMARK_HOME/thread_killer.sh &
		$BENCHMARK_HOME/run.sh $METHOD $thread
		#====>> finish benchmark
		#$BENCHMARK_HOME/stop_server.sh

		#echo "====== finish run for buffer pool $cache GB, #threads=$thread, take some rest for $SLEEP_BETWEEN_BM seconds ===="
		#sleep $SLEEP_BETWEEN_BM 
	done
done
