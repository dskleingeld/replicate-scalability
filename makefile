# point this to a directory having at least 10GB of free space
SCRATCH = /var/scratch/${USER}

data/twitter_rv_compressed: | data
	cd data \
	&& wget http://an.kaist.ac.kr/~haewoon/release/twitter_social_graph/twitter_rv.zip \
	unzip twitter_rv.zip

data/uk_2007_05_compressed: | data
	cd data \
	&& wget http://data.law.di.unimi.it/webdata/uk-2007-05/uk-2007-05.graph \
	&& mv uk-2007-05.graph uk-2007-05_compressed

dependencies/spark/sbin/start-all.sh: | tmp
	wget -O tmp/spark-3.0.1-bin-hadoop2.7.tgz https://apache.newfountain.nl/spark/spark-3.0.1/spark-3.0.1-bin-hadoop2.7.tgz
	tar zxf tmp/spark-3.0.1-bin-hadoop2.7.tgz -C dependencies
	mv dependencies/spark-3.0.1-bin-hadoop2.7 dependencies/spark
	rm tmp/spark-3.0.1-bin-hadoop2.7.tgz

tmp/sbt/bin/sbt: | tmp
	# mkdir -p tmp/sbt
	wget -O tmp/sbt.tgz https://github.com/sbt/sbt/releases/download/v1.4.0/sbt-1.4.0.tgz
	tar zxf tmp/sbt.tgz -C tmp/

something: tmp/sbt/bin/sbt
	# cd src/spark/PageRank \
	# && sbt

test: something
	echo "done"

all:
	deploy

deploy: dependencies/spark/sbin/start-all.sh
	bash deploy/graphx_pagerank.sh

.PHONY: rustup datadir

# these should both not be 'recreated' if the dir content changes
# use order-only prerequisite (target: | prerequisite)
data:
	mkdir -p ${SCRATCH}/data
	ln -s ${SCRATCH}/data data
tmp:
	mkdir -p ${SCRATCH}/tmp
	ln -s ${SCRATCH}/tmp tmp

rustup:
	ifeq (, $(shell which cargo))
	$(error "No cargo (rust compiler) in $(PATH), consider installing \"rustup: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh\"")
	endif

