#!/usr/bin/bash
PORT=7077

function node_list()
{
	preserve -long-list \
		| grep ${resv_numb} \
		| cut -f 9-
}

function wait_for_allocation()
{
	printf "waiting for nodes " >&2
	while [ "$(node_list)" == "-" ]
	do
		sleep 0.25
		printf "." >&2
	done
	echo "" >&2
}

#args: list of node dns names
function to_infiniband_ips()
{
	SITE_IP=10.149.1
	for node in $@; do
		NODE_ID=$(echo ${node:5:6}) #node102 -> 02
		printf "${SITE_IP}.${NODE_ID} "
	done
	echo ""
}

function deploy_spark_cluster()
{
	numb_nodes=${1:-2} #default 2
	duration=${2:-01} #default 1min

	resv_numb=$(preserve -# ${numb_nodes} -t 00:${duration}:05 | head -n 1 | cut -d ' ' -f 3) #TODO FIXME 10 is only for testing
	resv_numb=${resv_numb::-1}

	wait_for_allocation
	nodes=$(node_list)
	main=$(node_list | cut -d ' ' -f 1)
	workers=$(node_list | cut -d ' ' -f 2-)

	#launch spark master
	echo updating spark config file >&2
	workers_ips=$(to_infiniband_ips $workers)
	workers_list=$(echo $workers_ips | tr " " "\n")
	echo $workers_list > dependencies/spark/conf/slaves

	ssh_output=$(ssh $main <<- EOF
		bash ${PWD}/dependencies/spark/sbin/start-all.sh
EOF
)
	echo spark://${main}:${PORT} $main $workers
}

