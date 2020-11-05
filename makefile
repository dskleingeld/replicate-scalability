MAKEFLAGS+="-j -l $(shell expr $(shell grep -c ^processor /proc/cpuinfo) / 3) "
# use up to a third of the frontend running makefile jobs

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

# note: adding twitter_mpi causes quota exceeded (uses > 100Gb)
# note: adding graph500-25 already causes no space left on device during runs
DATASETS= wiki-Talk dota-league datagen-8_0-fb #graph500-25 #twitter_mpi 
DATA=$(addprefix data/, ${DATASETS})

all:
	deploy

############################################################################################################
# Data
############################################################################################################

# this works as long as we specify non implicit rules for all other
# zip files as make uses implicit rules as a last resort
%.zip: | data
	wget -q -O $@ https://atlarge.ewi.tudelft.nl/graphalytics/zip/$(notdir $@)

%.e: | %.zip
	# unzip -j data/datagen-7_7-zf.zip datagen-7_7-zf/datagen-7_7-zf.e -d data/	
	unzip -j $| $(basename $(notdir $@))/$(notdir $@) -d $(dir $@)

%.u32e: %.e tmp/cargo src/node_normaliser/
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

# note: the COST rust executables for conversion are generated on demand when they are used

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

src/rust/pagerank: src/rust/src/bin/pagerank.rs | tmp/cargo
	tmp/cargo/bin/cargo build --manifest-path src/rust/Cargo.toml --release --bin pagerank
	ln -fs ${PWD}/src/rust/{target/release/,}pagerank

src/rust/label_prop: src/rust/src/bin/pagerank.rs | tmp/cargo
	tmp/cargo/bin/cargo build --manifest-path src/rust/Cargo.toml --release --bin label_prop
	ln -fs ${PWD}/src/rust/{target/release/,}label_prop

src/rust/stats: | tmp/cargo
	tmp/cargo/bin/cargo build --manifest-path src/rust/Cargo.toml --release --bin stats
	ln -fs src/rust/{target/release/,}stats

############################################################################################################
# Other
############################################################################################################

.PHONY: clean deploy hello cost test stats 

stats: src/rust/stats
stats: data/datagen-7_7-zf.nodes
	src/rust/stats vertex data/datagen-7_7-zf

test: data/wiki-Talk.u32e
test: src/rust/label_prop
test: src/spark/LabelProp/LabelProp.jar
	# bash experiments/label_prop/single-threaded.sh wiki-Talk
	bash experiments/label_prop/scalable.sh wiki-Talk


# cost: experiments/pagerank/single-threaded.csv 
cost: experiments/pagerank/scalable.csv

experiments/pagerank/single-threaded.csv: $(addsuffix .upper, ${DATA})
experiments/pagerank/single-threaded.csv: $(addsuffix .nodes, ${DATA})
experiments/pagerank/single-threaded.csv: src/rust/pagerank
	bash experiments/pagerank/single-threaded.sh ${DATASETS}

experiments/pagerank/scalable.csv: $(addsuffix .u32e, ${DATA})
experiments/pagerank/scalable.csv: src/spark/PageRank/PageRank.jar
	bash experiments/pagerank/scalable.sh ${DATASETS}

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
