# !/bin/bash
source const.sh


#Now start the server and measure the recovery time 
sleep 5
RECV_FILE=rec_trace.out

echo "Start the server after crash, see trace file $RECV_FILE"
$BENCHMARK_HOME/start_server.sh 3 2>&1 | tee $RECV_FILE
