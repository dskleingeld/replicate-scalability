#!/usr/bin/bash

source deploy/spark.sh

spark_url=$(deploy_spark_cluster)

echo spark_url: $spark_url
bash dependencies/spark/bin/spark-submit \
	--class org.apache.spark.examples.PageRankExample \
	--master $spark_url \
	--deploy-mode cluster \
	src/spark/PageRank/pagerank.jar
	
