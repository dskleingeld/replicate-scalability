#!/usr/bin/bash

# working dir should be the root of the project, (call this from there)

USER="$(whoami)"
RESERVATION_DUR=1
DATASET=datagen-7_7-zf

	# && ./src/rust/pagerank hilbert /local/$USER/$DATASET 32791267 \
bash deploy/binary.sh $RESERVATION_DUR "
	cd $PWD \
	&& mkdir -p /local/$USER \
	&& cp {data,/local/$USER}/$DATASET.upper \
	&& cp {data,/local/$USER}/$DATASET.lower \
	&& cp {data,/local/$USER}/$DATASET.nodes \
	&& cp {data,/local/$USER}/$DATASET.edges \
	&& src/rust/pagerank vertex /local/$USER/$DATASET 32791267
	&& src/rust/pagerank hilbert /local/$USER/$DATASET 32791267 \
"
