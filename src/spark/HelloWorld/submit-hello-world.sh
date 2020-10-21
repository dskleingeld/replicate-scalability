#!/usr/bin/bash

echo "Compiling and assembling application..."
java \
	-Dsbt.ivy.home=tmp/.ivy2/ \
	-Divy.home=tmp/.ivy2/ \
	-jar ../../../tmp/sbt/bin/sbt-launch.jar \
	assembly

# Directory where spark-submit is defined
# Install spark from https://spark.apache.org/downloads.html
SPARK_HOME=../../../dependencies/spark

# JAR containing a simple hello world
JARFILE=target/scala-2.12/HelloWorld-assembly-0.1.0.jar

# Run it locally
${SPARK_HOME}/bin/spark-submit --class HelloWorld --master local $JARFILE
