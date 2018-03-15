# !/bin/bash
#usage: ./autorun.sh
source const.sh

#cache_arr=(3)
thread_arr=(8 16 32 64 128)
cache_arr=(256 512 1024 2048 3072 4096 5120 10240)

#cache_arr=(512 1024)
#thread_arr=(64)

echo "cache_arr[@] = $cache_arr[@]"

for cache in "${cache_arr[@]}"; do
echo "========  Buffer pool = $cache GB ============" 
	for thread in "${thread_arr[@]}"; do
		echo "========  Number of client threads = $thread ============" 

		#if [ $IS_RESET -eq 1 ]; then
		#sudo umount $DES_DIR 
		#sudo mkfs -t ext4 -F $DEV1
		#sudo mount $DEV1 $DES_DIR -o noatime -o nobarrier
		#sudo chown -R vldb:vldb $DES_DIR 
		#fi

		#reset_debug.sh can be used seperatly or embedded
		$BENCHMARK_HOME/reset_debug.sh		

		echo "sleep $SLEEP_CP seconds after cp..."
		sleep $SLEEP_CP

		$BENCHMARK_HOME/start_server.sh $cache &
		echo "sleep $SLEEP_DB_LOAD seconds before run the benchmark..."
		sleep $SLEEP_DB_LOAD 
		$BENCHMARK_HOME/run.sh $METHOD $thread
		#====>> finish benchmark
		$BENCHMARK_HOME/stop_server.sh
		# Get the number of flush trace
		echo "====== finish run for buffer pool $cache GB, #threads=$thread, take some rest for $SLEEP_BETWEEN_BM seconds ===="
		sleep $SLEEP_BETWEEN_BM 
	done
done
