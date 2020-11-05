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
import org.apache.spark.graphx.lib.LabelPropagation
import org.apache.spark.sql.SparkSession

object LabelProp {
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
    println("graph loaded")
    // Run LabelProp, second arg is max numb of iterations
    val labels = LabelPropagation.run(graph, 1)
    println("test")

    // count non root labels
    // scala tuple access: tuple_.n with n in {1...tuple_len)
    val non_roots = labels.vertices.filter(x => x._1 != x._2).count()
    println("non roots: ", non_roots)

    spark.stop()
  }
}
// scalastyle:on println
