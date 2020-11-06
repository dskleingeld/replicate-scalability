#!/usr/bin/bash

# working dir should be the root of the project, (call this from there)

USER="$(whoami)"
RESERVATION_DUR=15
DATASETS=( "$@" ) #turn args into array

function commands()
{
	DATASET=$1
	echo "
TIMEFORMAT="%R"
rm -rf /local/$USER
mkdir -p /local/$USER
cd $PWD
cp {data,/local/$USER}/$DATASET.u32e

ls /local/$USER
echo vertex
{ /usr/bin/time -f %e $PWD/src/rust/to_vertex /local/$USER/$DATASET.u32e /local/$USER/$DATASET; } 2>&1
echo hilbert
{ /usr/bin/time -f %e $PWD/src/rust/to_hilbert /local/$USER/$DATASET; } 2>&1
"
}

for dataset in ${DATASETS[@]}
do
	COMMANDS=$(commands $dataset)
	out=$(bash deploy/binary.sh $RESERVATION_DUR "$COMMANDS")
	echo dataset: $dataset >> experiments/conversion/time.txt
	echo "$out" >> experiments/conversion/time.txt
done
