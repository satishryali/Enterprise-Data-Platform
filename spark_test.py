from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("KubernetesDistributionTest")
    .getOrCreate()
)

print("Spark application started")
print("Master:", spark.sparkContext.master)

df = spark.range(0, 1_000_000).repartition(20)

print("Number of partitions:", df.rdd.getNumPartitions())

result = (
    df.rdd
      .map(lambda row: row[0])
      .mapPartitions(lambda iterator: [sum(iterator)])
      .collect()
)

print("Partition results:", result)

spark.stop()