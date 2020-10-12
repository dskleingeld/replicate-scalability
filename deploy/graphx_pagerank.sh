#!/usr/bin/bash

N_NODES=2
DURATION=00 #minutes 00-15

resv_numb=$(preserve -# ${N_NODES} -t 00:${DURATION}:10 | head -n 1 | cut -d ' ' -f 3) #TODO FIXME 10 is only for testing
resv_numb=${resv_numb::-1}

function node_list()
{
	preserve -long-list \
		| grep ${resv_numb} \
		| cut -f 9-
}

printf "waiting to get nodes allocated"
while [ "$(node_list)" == "-" ]
do
	sleep 0.25
	printf "."
done
echo ""

echo $(node_list)
#launch spark master

