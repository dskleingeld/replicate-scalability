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

# currently not used
function write_spark_config()
{
	cat > ${PWD}/dependencies/spark/conf/spark-env.sh << EOF
#!/usr/bin/bash bash
SPARK_EXECUTOR_CORES=4
SPARK_EXECUTOR_MEMORY=4g
SPARK_LOCAL_DIRS=tmp/spark
SPARK_MASTER_WEBUI_PORT=12345
SPARK_WORKER_INSTANCES=2
EOF

	# see: https://spark.apache.org/docs/latest/configuration.html
	cat > ${PWD}/dependencies/spark/conf/spark-defaults.conf << EOF
spark.executor.memory 	32g
spark.eventLog.dir 		tmp/spark
spark.eventLog.enabled  true
EOF
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
	$(write_spark_config)

	ssh_output=$(ssh $main <<- EOF
		bash ${PWD}/dependencies/spark/sbin/start-all.sh
EOF
)
	# make sure ssh output is not captured
	# by the calling function by redirecting it to 
	# stderr
	echo ssh output: $ssh_output >&2

	echo spark://${main}:${PORT} $main $workers
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
workers=$(echo $out | cut -d ' ' -f 3-)

echo $out
echo spark_url: $spark_url
echo main: $main
echo workers: $workers

# TODO ssh into master then run this cirumventing cluster mode not working
# TODO script goes through all works calls jps and checks if executor is there
# running with deploy mode client instead of cluster works too
log4j_setting="-Dlog4j.configuration=file:${PWD}/log4j.properties"

ssh $main <<- EOF
bash ${PWD}/dependencies/spark/bin/spark-submit \
	--class ${class} \
	--name test_please_work \
	--master ${spark_url} \
	--deploy-mode client \
	--supervise \
	--executor-memory 5G \
	--total-executor-cores 5 \
	--driver-cores 3 \
	--driver-memory 3G \
	--driver-java-options "${log4j_setting}" \
	--conf "spark.executor.extraJavaOptions=${log4j_setting}" \
	"${jar}" \
	"${graph}"
EOF
