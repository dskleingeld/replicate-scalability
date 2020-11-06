#!/usr/bin/bash

# working dir should be the root of the project, (call this from there)

USER="$(whoami)"
RESERVATION_DUR=15
DATASETS=( "$@" ) #turn args into array
# we use an array to make sure looping works if we have
# a single item

function commands()
{
	DATASET=$1
	echo "
TIMEFORMAT="%R"
rm -rf /local/$USER
mkdir -p /local/$USER
cd $PWD
cp {data,/local/$USER}/$DATASET.upper
cp {data,/local/$USER}/$DATASET.lower
cp {data,/local/$USER}/$DATASET.nodes
cp {data,/local/$USER}/$DATASET.edges

largest_vertex_id=\$(src/rust/stats vertex /local/$USER/$DATASET)
largest_vertex_id=\$(echo -e "\$largest_vertex_id" | rev | cut -d ' ' -f 1 | rev)
echo array_size: \$largest_vertex_id
echo vertex
{ /usr/bin/time -f %e src/rust/label_prop vertex /local/$USER/$DATASET \$largest_vertex_id; } 2>&1
echo hilbert
{ /usr/bin/time -f %e src/rust/label_prop hilbert /local/$USER/$DATASET \$largest_vertex_id; } 2>&1
"
}

date >> experiments/label_prop/single-threaded-stats.txt
for dataset in ${DATASETS[@]}
do
	COMMANDS=$(commands $dataset)
	out=$(bash deploy/binary.sh $RESERVATION_DUR "$COMMANDS")
	echo dataset: $dataset >> experiments/label_prop/single-threaded-stats.txt
	echo "$out" >> experiments/label_prop/single-threaded-stats.txt
done
