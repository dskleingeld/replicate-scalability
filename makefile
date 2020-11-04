#
# $@ is a macro that refers to the target
# $< is a macro that refers to the first dependency
# basename -> $(basename src/foo.c src-1.0/bar hacks) 
# produces 'src/foo src-1.0/bar hacks'
# notdir -> $(notdir src/foo.c hacks)
# produces ‘foo.c hacks’
# throughout here we use '|' any prerequisites following this are
# order only, their target is not updated if they change
#

# point this to a directory having at least 10GB of free space
SCRATCH = /var/scratch/${USER}
# when using cargo outside of this makefile you must
# export these variables in the shell you are using
export RUSTUP_HOME=${PWD}/tmp/rustup
export CARGO_HOME=${PWD}/tmp/cargo

all:
	deploy

############################################################################################################
# Data
############################################################################################################

data/datagen-7_7-zf.zip: | data
	wget -O $@ https://atlarge.ewi.tudelft.nl/graphalytics/zip/datagen-7_7-zf.zip
data/datagen-7_7-zf.e: | data/datagen-7_7-zf.zip
	# unzip into the dir from the dependency the edges file
	unzip -j data/datagen-7_7-zf.zip datagen-7_7-zf/datagen-7_7-zf.e -d data
	rm data/datagen-7_7-zf.zip

%.u32e: %.e tmp/cargo
	tmp/cargo/bin/cargo run --manifest-path src/node_normaliser/Cargo.toml --release -- $< $@

# will also produce .edges
%.nodes: %.u32e tmp/cargo
	tmp/cargo/bin/cargo run --manifest-path src/rust/Cargo.toml --release --bin to_vertex -- $< $(basename $@)

# will also produce .lower
%.upper: %.nodes tmp/cargo
	tmp/cargo/bin/cargo run --manifest-path src/rust/Cargo.toml --release --bin to_hilbert -- $(basename $@)

############################################################################################################
# Compilers and conversion tools
############################################################################################################

tmp/webgraph/webgraph.jar: | tmp
	mkdir -p $(dir $@)
	wget -O tmp/webgraph-deps.tar.gz http://webgraph.di.unimi.it/webgraph-deps.tar.gz
	tar zxf tmp/webgraph-deps.tar.gz -C dependencies/webgraph
	rm tmp/webgraph-deps.tar.gz	
	wget -O $@ https://search.maven.org/remotecontent?filepath=it/unimi/dsi/webgraph/3.6.5/webgraph-3.6.5.jar

tmp/spark/sbin/start-all.sh: | tmp
	wget -O tmp/spark-3.0.1-bin-hadoop2.7.tgz https://apache.newfountain.nl/spark/spark-3.0.1/spark-3.0.1-bin-hadoop2.7.tgz
	tar zxf tmp/spark-3.0.1-bin-hadoop2.7.tgz -C dependencies
	mv dependencies/spark-3.0.1-bin-hadoop2.7 dependencies/spark
	rm tmp/spark-3.0.1-bin-hadoop2.7.tgz

tmp/cargo:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs >> rustup.sh
	chmod +x rustup.sh
	bash rustup.sh -y --no-modify-path --profile minimal
	rm rustup.sh

tmp/sbt/bin/sbt: | tmp
	wget -O tmp/sbt.tgz https://github.com/sbt/sbt/releases/download/v1.4.0/sbt-1.4.0.tgz
	tar zxf tmp/sbt.tgz -C tmp/
	rm tmp/sbt.tgz

tmp/jdk-15/bin/java: | tmp
	wget -O tmp/openjdk.tar.gz https://download.java.net/java/GA/jdk15/779bf45e88a44cbd9ea6621d33e33db1/36/GPL/openjdk-15_linux-x64_bin.tar.gz
	tar zxf tmp/openjdk.tar.gz -C tmp/

############################################################################################################
# Experiment Executables
############################################################################################################

# note: the COST rust executables are generated on demand when they are used

src/spark/PageRank/PageRank.jar: src/spark/PageRank/src/main/scala/PageRank.scala
src/spark/PageRank/PageRank.jar: src/spark/PageRank/build.sbt
src/spark/PageRank/PageRank.jar: tmp/sbt/bin/sbt
	cd src/spark/PageRank \
	&& java \
		-Dsbt.ivy.home=tmp/.ivy2/ \
		-Divy.home=tmp/.ivy2/ \
		-jar ../../../tmp/sbt/bin/sbt-launch.jar \
		assembly
		# package
	mv src/spark/PageRank/target/scala-2.12/*.jar \
		src/spark/PageRank/PageRank.jar
	rm -rf src/spark/PageRank/target

src/spark/LabelProp/LabelProp.jar: src/spark/LabelProp/src/main/scala/LabelProp.scala
src/spark/LabelProp/LabelProp.jar: src/spark/LabelProp/build.sbt
src/spark/LabelProp/LabelProp.jar: tmp/sbt/bin/sbt
	cd src/spark/LabelProp \
	&& java \
		-Dsbt.ivy.home=tmp/.ivy2/ \
		-Divy.home=tmp/.ivy2/ \
		-jar ../../../tmp/sbt/bin/sbt-launch.jar \
		assembly
		# package
	mv src/spark/LabelProp/target/scala-2.12/*.jar \
		src/spark/LabelProp/LabelProp.jar
	rm -rf src/spark/LabelProp/target

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
	rm -rf src/spark/HelloWorld/target

src/rust/pagerank: src/rust/src | tmp/cargo
	tmp/cargo/bin/cargo build --manifest-path src/rust/Cargo.toml --release --bin pagerank
	ln -s ${PWD}/src/rust/{target/release/,}pagerank

src/rust/stats: | tmp/cargo
	tmp/cargo/bin/cargo build --manifest-path src/rust/Cargo.toml --release --bin stats
	ln -s src/rust/{target/release/,}stats

############################################################################################################
# Other
############################################################################################################

.PHONY: clean deploy hello cost test

stats: src/rust/stats
stats: data/datagen-7_7-zf.nodes
	src/rust/stats vertex data/datagen-7_7-zf

# cost: experiments/pagerank/single-threaded.csv 
cost: experiments/pagerank/scalable.csv

experiments/pagerank/single-threaded.csv: data/datagen-7_7-zf.nodes
experiments/pagerank/single-threaded.csv: data/datagen-7_7-zf.upper
experiments/pagerank/single-threaded.csv: src/rust/pagerank
	bash experiments/pagerank/single-threaded.sh

experiments/pagerank/scalable.csv: data/datagen-7_7-zf.u32e
experiments/pagerank/scalable.csv: src/spark/PageRank/PageRank.jar
	bash experiments/pagerank/scalable.sh

# these should both not be 'recreated' if the dir content changes
# use order-only prerequisite (target: | prerequisite)
data:
	mkdir -p ${SCRATCH}/data
	ln -s ${SCRATCH}/data data
tmp:
	mkdir -p ${SCRATCH}/tmp
	ln -s ${SCRATCH}/tmp tmp

# remove build artefacts and logs but leave downloaded data intact
clean:
	rm -f src/spark/HelloWorld/HalloWorld.jar
	rm -f src/spark/PageRank/PageRank.jar
	rm -f src/spark/LabelProp/LabelProp.jar
	rm -rf dependencies/spark/work/* # clear spark logs	
