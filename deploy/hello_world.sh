#!/usr/bin/bash

source deploy/spark.sh

spark_url=$(deploy_spark_cluster)

echo spark_url: $spark_url
bash dependencies/spark/bin/spark-submit \
	--class HelloWorld \
	--master $spark_url \
	--deploy-mode cluster \
	src/spark/HelloWorld/HelloWorld.jar
