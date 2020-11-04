#!/usr/bin/bash

# working dir should be the root of the project, (call this from there)
JAR=src/spark/PageRank/PageRank.jar
CLASS=PageRank
RESERVATION_DUR=15
CORES_PER_NODE=16
USER="$(whoami)"

source deploy/spark.sh

function move_data()
{
	DATASET=$1
	echo "
rm -rf /local/$USER
mkdir -p /local/$USER
cp {$PWD/data,/local/$USER}/$DATASET
"
}

function min()
{
	echo $(($1<$2 ? $1 : $2))
}

# https://stackoverflow.com/questions/24622108/apache-spark-the-number-of-cores-vs-the-number-of-executors
function submit()
{
	log4j_setting="-Dlog4j.configuration=file:${PWD}/log4j.properties"
	MEMORY_PER_NODE=48G #nodes seem to have 62

	spark_url=$1
	total_cores=$2 
	cores_per_node=$(min $total_cores $CORES_PER_NODE)
	dataset=/local/$USER/$3
	echo "
time bash ${PWD}/dependencies/spark/bin/spark-submit \
	--class ${CLASS} \
	--name test_please_work \
	--master ${spark_url} \
	--deploy-mode client \
	--supervise \
	--num-executors 1000 \
	--total-executor-cores ${total_cores} \
	--executor-memory ${MEMORY_PER_NODE} \
	--executor-cores ${cores_per_node} \
	--driver-cores 3 \
	--driver-memory 4G \
	--driver-java-options "${log4j_setting}" \
	--conf "spark.executor.extraJavaOptions=${log4j_setting}" \
	"${PWD}/${JAR}" \
	"${dataset}"
"
}

function div_round_up()
{
	nom=$1
	denom=$2
	denom_m1=$(expr $denom - 1)
	new_nom=$(expr $nom + $denom_m1)
	expr $new_nom / $denom
}

# use u32 edge list as its smaller then the original and
# we do not want to give spark a disadvantage
DATASETS=( datagen-7_7-zf.u32e )
TOTAL_CORES=( 2 ) #4 8 16 32 64 128 256
for dataset in $DATASETS
do
	for total_cores in $TOTAL_CORES
	do
		# rounding up
		nodes=$(div_round_up $total_cores $CORES_PER_NODE)
		nodes=$(expr $nodes + 1) # separate node for the main
		echo reserving $nodes nodes

		# reserve and await cluster
		out=$(deploy_spark_cluster $nodes $RESERVATION_DUR)
		spark_url=$(echo $out | cut -d ' ' -f 1)
		main=$(echo $out | cut -d ' ' -f 2)
		nodes=$(echo $out | cut -d ' ' -f 2-)

		# move the data on the master and all workers to the 
		# faster locally mounted /local
		move_data_cmds=$(move_data $dataset)
		for node in $nodes
		do
			#run ssh in parallel (fork)
			(ssh $node -t "$move_data_cmds") &
		done
		wait #wait until (subshells) ssh jobs are done

		# create commands to run on master
		submit_cmd=$(submit $spark_url $total_cores $dataset)

		ssh $main -t "$submit_cmd"
	done
done
