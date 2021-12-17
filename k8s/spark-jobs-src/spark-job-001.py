import sys
import pyspark
from pyspark.sql.types import *
from pyspark.sql.functions import *
from pyspark.sql.avro.functions import *
from pyspark.sql import SparkSession

source=sys.argv[1]
target=sys.argv[2]

spark = SparkSession\
    .builder\
    .appName("repartition-job")\
    .getOrCreate()

jsonOptions = { "timestampFormat": "yyyy-MM-dd'T'HH:mm:ss" }

# Define schema of json
schema = StructType() \
  .add('ts', TimestampType(), True) \
  .add('thing_id', IntegerType(), True) \
  .add('temperature', DoubleType(), True) \
  .add('humidity', DoubleType(), True)

spark.read.json(source) \
  .select(from_json(col("value").cast("string"), schema, jsonOptions).alias("data")) \
  .select( \
     col("data.temperature").alias("temperature"), \
     col("data.humidity").alias("humidity"), \
     col("data.thing_id").alias("thing_id"), \
     col("data.ts").alias("event_ts"), \
     hour(col("data.ts")).alias("hour"), \
     dayofmonth(col("data.ts")).alias("month"), \
     month(col("data.ts")).alias("month"), \
     year(col("data.ts")).alias("year")) \
  .repartition("year", "month", "day", "hour") \
  .write \
  .partitionBy("year", "month", "day", "hour") \
  .mode("overwrite") \
  .parquet(target)

spark.stop()
