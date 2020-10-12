data/twitter_rv_compressed:
	cd data \
	&& wget http://an.kaist.ac.kr/~haewoon/release/twitter_social_graph/twitter_rv.zip \
	unzip twitter_rv.zip

data/uk_2007_05_compressed:
	cd data \
	&& wget http://data.law.di.unimi.it/webdata/uk-2007-05/uk-2007-05.graph \
	&& mv uk-2007-05.graph uk-2007-05_compressed

dependencies/spark/sbin/start-all.sh:
	wget -O /tmp/spark-3.0.1-bin-hadoop2.7.tgz https://apache.newfountain.nl/spark/spark-3.0.1/spark-3.0.1-bin-hadoop2.7.tgz
	tar zxf /tmp/spark-3.0.1-bin-hadoop2.7.tgz -C dependencies
	mv dependencies/spark-3.0.1-bin-hadoop2.7 dependencies/spark

setup: dependencies/spark/sbin/start-all.sh

all:
	setup

.PHONY: rustup temp

rustup:
	ifeq (, $(shell which cargo))
	$(error "No cargo (rust compiler) in $(PATH), consider installing \"rustup: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh\"")
	endif

temp:
	mkdir -p temp
