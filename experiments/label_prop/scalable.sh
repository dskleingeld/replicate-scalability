#!/usr/bin/bash

# working dir should be the root of the project, (call this from there)
JAR=src/spark/LabelProp/LabelProp.jar
CLASS=LabelProp
RESERVATION_DUR=15
CORES_PER_NODE=32
USER="$(whoami)"

source deploy/spark.sh

function move_data()
{
	DATASET=$1
	echo "
rm -rf /local/$USER
mkdir -p /local/$USER
cp {$PWD/data,/local/$USER}/$DATASET.u32e
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
	# use u32 edge list as its smaller then the original and
	# we do not want to give spark a disadvantage
	workers=$3
	dataset=/local/$USER/$4.u32e
	echo "
{ /usr/bin/time -f %e \
bash ${PWD}/dependencies/spark/bin/spark-submit \
	--class ${CLASS} \
	--name test_please_work \
	--master ${spark_url} \
	--deploy-mode client \
	--supervise \
	--num-executors ${workers} \
	--total-executor-cores ${total_cores} \
	--executor-memory ${MEMORY_PER_NODE} \
	--executor-cores ${cores_per_node} \
	--driver-cores 3 \
	--driver-memory 48G \
	--driver-java-options "${log4j_setting}" \
	--conf "spark.executor.extraJavaOptions=${log4j_setting}" \
	"${PWD}/${JAR}" \
	"${dataset}"; } 2>&1
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

date >> experiments/label_prop/scalable-stats.txt
DATASETS=( "$@" ) #turn args into array
TOTAL_CORES=( 64 128 256 )
for dataset in ${DATASETS[@]}
do
	for total_cores in ${TOTAL_CORES[@]}
	do
		# rounding up
		nodes=$(div_round_up $total_cores $CORES_PER_NODE)
		nodes=$(expr $nodes + 1) # separate node for the main
		echo dataset: $dataset, total_cores: $total_cores
		echo reserving $nodes nodes

		# reserve and await cluster
		out=$(deploy_spark_cluster $nodes $RESERVATION_DUR)
		id=$(echo $out | cut -d ' ' -f 1)
		spark_url=$(echo $out | cut -d ' ' -f 2)
		main=$(echo $out | cut -d ' ' -f 3)
		nodes=$(echo $out | cut -d ' ' -f 3-)

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
		numb_workers=$(expr $nodes - 1)
		submit_cmd=$(submit $spark_url $total_cores $numb_workers $dataset)

		out=$(ssh $main -t "$submit_cmd")
		echo dataset: $dataset >> experiments/label_prop/scalable-stats.txt
		echo total_cores: $total_cores >> experiments/label_prop/scalable-stats.txt
		echo "$out" >> experiments/label_prop/scalable-stats.txt
		preserve -c $id
	done
done
