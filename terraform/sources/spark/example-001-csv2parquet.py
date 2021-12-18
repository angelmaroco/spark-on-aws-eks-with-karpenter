import sys
import uuid
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName('example-001-csv2parquet').getOrCreate()

df = spark.read.format("csv").option("header", "true").load(sys.argv[1])

print(df.count())

path_output = "{uri}/{uuid}/".format(uri=sys.argv[2], uuid=uuid.uuid4())

df.write.parquet(path_output)

exit()
