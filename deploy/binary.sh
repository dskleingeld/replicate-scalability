#!/usr/bin/bash

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

numb_nodes=1 #default 2
duration=${1:-01} #default 1min

resv_numb=$(preserve -# ${numb_nodes} -t 00:${duration}:05 | head -n 1 | cut -d ' ' -f 3)
resv_numb=${resv_numb::-1}

wait_for_allocation
node=$(node_list | cut -d ' ' -f 1)

command=$(echo "${@}" | tail -n +2)
echo connecting to $node >&2
ssh $node -t "$command"
