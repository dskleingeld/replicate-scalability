//adapted from https://github.com/apache/spark/blob/master/examples/src/main/scala/org/apache/spark/examples/graphx/PageRankExample.scala

/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import org.apache.spark.graphx.GraphLoader
import org.apache.spark.sql.SparkSession

object PageRank {
  def main(args: Array[String]): Unit = {
    // Creates a SparkSession.
    val spark = SparkSession
      .builder
      .appName(s"${this.getClass.getSimpleName}")
      .getOrCreate()
    val sc = spark.sparkContext

    // $example on$
    // Load the edges as a graph
    val edgeListPath = args(0)
    println("edgeListPath: %s", edgeListPath)
    val graph = GraphLoader.edgeListFile(sc, edgeListPath)
    // Run PageRank
    val ranks = graph.pageRank(0.0001).vertices
    // // Join the ranks with the usernames
    // val users = sc.textFile("data/graphx/users.txt").map { line =>
    //   val fields = line.split(",")
    //   (fields(0).toLong, fields(1))
    // }
    // val ranksByUsername = users.join(ranks).map {
    //   case (id, (username, rank)) => (username, rank)
    // }
    // // Print the result
    // println(ranksByUsername.collect().mkString("\n"))
    // // $example off$
    println("done")
    spark.stop()
  }
}
// scalastyle:on println
