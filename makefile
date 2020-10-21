# point this to a directory having at least 10GB of free space
SCRATCH = /var/scratch/${USER}

data/twitter_rv.zip: | data
	wget -O data/twitter_rv.zip http://an.kaist.ac.kr/~haewoon/release/twitter_social_graph/twitter_rv.zip
	unzip -d data data/twitter_rv.zip
	rm data/twitter_rv.zip

# these are in webgraph format
data/uk-2007-05.graph: | data
	wget -O $@ http://data.law.di.unimi.it/webdata/uk-2007-05/uk-2007-05.graph
data/uk-2007-05.properties: | data
	wget -O $@ http://data.law.di.unimi.it/webdata/uk-2007-05/uk-2007-05.properties
# convert the compressed graph to an edgelist
data/uk-2007-05.graph-txt: data/uk-2007-05.graph data/uk-2007-05.properties
data/uk-2007-05.graph-txt: dependencies/webgraph/webgraph.jar
data/uk-2007-05.graph-txt: dependencies/jdk-15/bin/java
	./dependencies/jdk-15/bin/java \
		-classpath "dependencies/webgraph/*" \
		it.unimi.dsi.webgraph.ASCIIGraph \
		$(basename $@) $(basename $@)

dependencies/webgraph/webgraph.jar: | tmp
	mkdir -p $(dir $@)
	wget -O tmp/webgraph-deps.tar.gz http://webgraph.di.unimi.it/webgraph-deps.tar.gz
	tar zxf tmp/webgraph-deps.tar.gz -C dependencies/webgraph
	rm tmp/webgraph-deps.tar.gz	
	wget -O $@ https://search.maven.org/remotecontent?filepath=it/unimi/dsi/webgraph/3.6.5/webgraph-3.6.5.jar

dependencies/spark/sbin/start-all.sh: | tmp
	wget -O tmp/spark-3.0.1-bin-hadoop2.7.tgz https://apache.newfountain.nl/spark/spark-3.0.1/spark-3.0.1-bin-hadoop2.7.tgz
	tar zxf tmp/spark-3.0.1-bin-hadoop2.7.tgz -C dependencies
	mv dependencies/spark-3.0.1-bin-hadoop2.7 dependencies/spark
	rm tmp/spark-3.0.1-bin-hadoop2.7.tgz

tmp/sbt/bin/sbt: | tmp
	wget -O tmp/sbt.tgz https://github.com/sbt/sbt/releases/download/v1.4.0/sbt-1.4.0.tgz
	tar zxf tmp/sbt.tgz -C tmp/
	rm tmp/sbt.tgz

dependencies/jdk-15/bin/java: | tmp
	wget -O tmp/openjdk.tar.gz https://download.java.net/java/GA/jdk15/779bf45e88a44cbd9ea6621d33e33db1/36/GPL/openjdk-15_linux-x64_bin.tar.gz
	tar zxf tmp/openjdk.tar.gz -C dependencies/

src/spark/PageRank/pagerank.jar: src/spark/PageRank/PageRank.scala
src/spark/PageRank/pagerank.jar: src/spark/PageRank/build.sbt
src/spark/PageRank/pagerank.jar: tmp/sbt/bin/sbt
	cd src/spark/PageRank \
	&& java \
		-Dsbt.ivy.home=tmp/.ivy2/ \
		-Divy.home=tmp/.ivy2/ \
		-jar ../../../tmp/sbt/bin/sbt-launch.jar \
		assembly
		# package
	mv src/spark/PageRank/target/scala-2.12/*.jar \
		src/spark/PageRank/pagerank.jar

src/spark/HelloWorld/HelloWorld.jar: src/spark/HelloWorld/src/main/scala/HelloWorld.scala
src/spark/HelloWorld/HelloWorld.jar: src/spark/HelloWorld/build.sbt
src/spark/HelloWorld/HelloWorld.jar: tmp/sbt/bin/sbt
	cd src/spark/HelloWorld \
	&& java \
		-Dsbt.ivy.home=tmp/.ivy2/ \
		-Divy.home=tmp/.ivy2/ \
		-jar ../../../tmp/sbt/bin/sbt-launch.jar \
		assembly
		# package
	mv src/spark/HelloWorld/target/scala-2.12/*.jar \
		src/spark/HelloWorld/HelloWorld.jar

test:
	echo "done"

all:
	deploy

deploy: dependencies/spark/sbin/start-all.sh
deploy: src/spark/PageRank/pagerank.jar
deploy: data/uk-2007-05.graph-txt
	bash deploy/graphx_pagerank.sh data/uk-2007-05.graph-txt

hello: dependencies/spark/sbin/start-all.sh
hello: src/spark/HelloWorld/HelloWorld.jar
hello: data/uk-2007-05.graph-txt
	bash deploy/hello_world.sh data/uk-2007-05.graph-txt


.PHONY: clean rustup deploy hello

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

clean:
	rm -f src/spark/HelloWorld/HalloWorld.jar
	rm -f src/spark/PageRank/pagerank.jar
	rm -rf dependencies/spark/work/*
