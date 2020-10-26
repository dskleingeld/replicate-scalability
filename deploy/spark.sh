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

if [ $# -lt 3 ] 
then 
	echo "usage spark.sh <path to graph> <path to jar> <class to run>"
	exit 22
fi

if [ $# -eq 4 ] 
then #hide logs from previous runs
	(cd dependencies/spark/work \
	&& for f in driver-*; do mv "${f}" ".${f}"; done)
fi

graph="${PWD}/${1}"
jar="${PWD}/${2}"
class=$3
spark_url=$(deploy_spark_cluster 2 5)
echo spark_url: $spark_url

bash dependencies/spark/bin/spark-submit \
	--class ${class} \
	--master $spark_url \
	--deploy-mode cluster \
	"${jar}" \
	"${graph}"
