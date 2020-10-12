#!/usr/bin/bash

function node_list()
{
	preserve -long-list \
		| grep ${resv_numb} \
		| cut -f 9-
}

function wait_for_allocation()
{
	printf "waiting for nodes "
	while [ "$(node_list)" == "-" ]
	do
		sleep 0.25
		printf "."
	done
	echo ""
}

function deploy_spark_cluster()
{
	numb_nodes=${1:-2} #default 2
	duration=${2:-1} #default 1min
	resv_numb=$(preserve -# ${numb_nodes} -t 00:${DURATION}:05 | head -n 1 | cut -d ' ' -f 3) #TODO FIXME 10 is only for testing
	resv_numb=${resv_numb::-1}

	wait_for_allocation
	main=$(node_list | cut -d ' ' -f 1)
	workers=$(node_list | cut -d ' ' -f 2-)

	#launch spark master
	echo writing spark config file
	workers_list=$(echo $workers | tr " " "\n")
	echo $workers_list > dependencies/spark/conf/slaves

	ssh $main <<EOF
bash ${PWD}/dependencies/spark/sbin/start-all.sh
EOF

	echo spark://${main}:PORT
}
