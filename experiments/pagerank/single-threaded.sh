#!/usr/bin/bash

# working dir should be the root of the project, (call this from there)

USER="$(whoami)"
RESERVATION_DUR=1
DATASETS="datagen-7_7-zf datagen-7_7-zf"

REMOTE_SCRIPT="
cd $PWD
mkdir -p /local/$USER

for DATASET in ${DATASETS}
do
	cp {data,/local/$USER}/\$DATASET.upper
	cp {data,/local/$USER}/\$DATASET.lower
	cp {data,/local/$USER}/\$DATASET.nodes
	cp {data,/local/$USER}/\$DATASET.edges

	time src/rust/pagerank vertex /local/$USER/\$DATASET 32791267
	time src/rust/pagerank hilbert /local/$USER/\$DATASET 32791267
done
"

out=$(bash deploy/binary.sh $RESERVATION_DUR "$REMOTE_SCRIPT")
echo out: "${out}"
