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
	echo workers ips: $workers_ips >&2
	workers_list=$(echo $workers_ips | tr " " "\n")
	echo $workers_list > dependencies/spark/conf/slaves

	ssh_output=$(ssh $main <<- EOF
		bash ${PWD}/dependencies/spark/sbin/start-all.sh
EOF
)
	echo spark://${main}:${PORT} $main
}

if [ $# -lt 3 ] 
then 
	echo "usage spark.sh <path to graph> <path to jar> <class to run>"
	exit 22
fi

if [ $# -eq 4 ] 
then #hide logs from previous runs
	(cd dependencies/spark/work; \
	for f in driver-*; do mv "${f}" ".${f}"; done; \
	for f in app-*; do mv "${f}" ".${f}"; done)
fi

graph="${PWD}/${1}"
jar="${PWD}/${2}"
class=$3

out=$(deploy_spark_cluster 3 5)
spark_url=$(echo $out | cut -d ' ' -f 1)
main=$(echo $out | cut -d ' ' -f 2)

# TODO script goes through all works calls jps and checks if executor is there
# running with deploy mode client instead of cluster works too
log4j_setting="-Dlog4j.configuration=file:${PWD}/log4j.properties"
CORES_PER_NODE=16
MEMORY_PER_NODE=48G #nodes seem to have 62

	# --total-executor-cores 5 \
ssh $main <<- EOF
bash ${PWD}/dependencies/spark/bin/spark-submit \
	--class ${class} \
	--name test_please_work \
	--master ${spark_url} \
	--deploy-mode client \
	--supervise \
	--num-executors 1000 \
	--executor-memory ${MEMORY_PER_NODE} \
	--executor-cores ${CORES_PER_NODE} \
	--driver-cores 3 \
	--driver-memory 4G \
	--driver-java-options "${log4j_setting}" \
	--conf "spark.executor.extraJavaOptions=${log4j_setting}" \
	"${jar}" \
	"${graph}"
EOF
