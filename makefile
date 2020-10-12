data/twitter_rv_compressed:
	cd data \
	&& wget http://an.kaist.ac.kr/~haewoon/release/twitter_social_graph/twitter_rv.zip \
	unzip twitter_rv.zip

data/uk_2007_05_compressed:
	cd data \
	&& wget http://data.law.di.unimi.it/webdata/uk-2007-05/uk-2007-05.graph \
	&& mv uk-2007-05.graph uk-2007-05_compressed

data/uk_2007_05_hilbert: data/uk-2007-05.graph rustup
	cd data \
	&&



all:
	data/twitter_rv

.PHONY: rustup

rustup:
	ifeq (, $(shell which cargo))
	$(error "No cargo (rust compiler) in $(PATH), consider installing \"rustup: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh\"")
	endif

temp:
	mkdir -p temp
