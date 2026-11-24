from pyspark.sql import SparkSession
import socket

spark = (
    SparkSession.builder
    .appName("KubernetesDistributionTest")
    .getOrCreate()
)

sc = spark.sparkContext

print("=== SPARK KUBERNETES DISTRIBUTION DEMO ===")
print("Driver hostname:", socket.gethostname())


def process_partition(iterator):
    # Result is sent to the driver. No shuffle between executors.
    hostname = socket.gethostname()
    total = sum(iterator)
    yield (hostname, total)


result = (
    sc.parallelize(range(10000), 2)
      .mapPartitions(process_partition)
      .collect()
)

print("=== PARTITION RESULTS (executor pod hostnames) ===")
for item in sorted(result, key=lambda x: x[0]):
    print(item)
print("=== EXECUTOR HOSTS ===")
for host in sorted({host for host, _ in result}):
    print(host)

spark.stop()
