#!/bin/bash
HOST=115.145.173.215
DB=tpcc1000
USER=vldb
WH=500
CONN=32
RUNTIME=1200
OUTPUT=tpcc-out-bpool-768.out

if [ -n $1 ]; then
	OUTPUT=$1
fi

#./tpcc_start -h$HOST -d$DB -u$USER -w$WH -c$CONN -l$RUNTIME > tpcc-out-bpool-256.out
./tpcc_start -h$HOST -d$DB -u$USER -w$WH -c$CONN -l$RUNTIME -i10 2>&1 | tee $OUTPUT 
