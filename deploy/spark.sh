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

function deploy_spark_cluster()
{
	numb_nodes=${1:-2} #default 2
	duration=${2:-01} #default 1min

	resv_numb=$(preserve -# ${numb_nodes} -t 00:${duration}:05 | head -n 1 | cut -d ' ' -f 3) #TODO FIXME 10 is only for testing
	resv_numb=${resv_numb::-1}

	wait_for_allocation
	main=$(node_list | cut -d ' ' -f 1)
	workers=$(node_list | cut -d ' ' -f 2-)

	#launch spark master
	echo updating spark config file >&2
	workers_list=$(echo $workers | tr " " "\n")
	echo $workers_list > dependencies/spark/conf/slaves

	ssh_output=$(ssh $main <<- EOF
		bash ${PWD}/dependencies/spark/sbin/start-all.sh
EOF
)
	# make sure ssh output is not captured
	# by the calling function by redirecting it to 
	# stderr
	echo ssh output: $ssh_output >&2

	echo spark://${main}:${PORT}
}
