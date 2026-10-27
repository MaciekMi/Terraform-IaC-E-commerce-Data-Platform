import sys
import logging
from datetime import datetime

from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import LongType, DecimalType, TimestampType


# ── Logging ──────────────────────────────────────────────────
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ── Parametry Glue Job ───────────────────────────────────────
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "SOURCE_BUCKET",
        "TARGET_BUCKET",
    ],
)


# ── Glue / Spark setup ───────────────────────────────────────
sc = SparkContext()

glue_context = GlueContext(sc)

spark = glue_context.spark_session

job = Job(glue_context)

job.init(args["JOB_NAME"], args)


SOURCE_BUCKET = args["SOURCE_BUCKET"]
TARGET_BUCKET = args["TARGET_BUCKET"]

RUN_DATE = datetime.utcnow().strftime("%Y-%m-%d")


logger.info(
    f"START | "
    f"job={args['JOB_NAME']} | "
    f"source={SOURCE_BUCKET} | "
    f"target={TARGET_BUCKET} | "
    f"date={RUN_DATE}"
)


# ── EXTRACT ──────────────────────────────────────────────────
input_path = f"s3://{SOURCE_BUCKET}/raw/orders/"

logger.info(f"Reading parquet from: {input_path}")

orders_raw = spark.read.parquet(input_path)

logger.info(f"Rows read: {orders_raw.count():,}")


# ── TRANSFORM — rzutowanie typów ─────────────────────────────
logger.info("Casting column types")

orders = (
    orders_raw
    .withColumn(
        "order_id",
        F.col("order_id").cast(LongType())
    )
    .withColumn(
        "customer_id",
        F.col("customer_id").cast(LongType())
    )
    .withColumn(
        "total_amount",
        F.col("total_amount").cast(DecimalType(12, 2))
    )
    .withColumn(
        "ordered_at",
        F.col("ordered_at").cast(TimestampType())
    )
)


# ── DATA QUALITY ─────────────────────────────────────────────
logger.info("Checking data quality")

invalid_rows = orders.filter(
    F.col("order_id").isNull()
    | F.col("customer_id").isNull()
    | F.col("total_amount").isNull()
    | (F.col("total_amount") < 0)
).count()

logger.info(f"Invalid rows found: {invalid_rows}")


orders = orders.filter(
    F.col("order_id").isNotNull()
    & F.col("customer_id").isNotNull()
    & F.col("total_amount").isNotNull()
    & (F.col("total_amount") >= 0)
)

logger.info(
    f"Rows after data quality filtering: {orders.count():,}"
)


# ── DEDUPLIKACJA ─────────────────────────────────────────────
logger.info("Removing duplicates by order_id")

before_dedup = orders.count()

orders = orders.dropDuplicates(["order_id"])

after_dedup = orders.count()

logger.info(
    f"Duplicates removed: {before_dedup - after_dedup}"
)


# ── KOLUMNY POCHODNE ─────────────────────────────────────────
logger.info("Adding derived columns")

orders_processed = (
    orders
    .withColumn(
        "order_date",
        F.to_date("ordered_at")
    )
    .withColumn(
        "order_year",
        F.year("ordered_at")
    )
    .withColumn(
        "order_month",
        F.month("ordered_at")
    )
    .withColumn(
        "processed_at",
        F.current_timestamp()
    )
    .withColumn(
        "etl_run_date",
        F.lit(RUN_DATE)
    )
)

logger.info(
    f"Transform complete. Output rows: "
    f"{orders_processed.count():,}"
)


# ── LOAD ─────────────────────────────────────────────────────
now = datetime.utcnow()

output_path = (
    f"s3://{TARGET_BUCKET}/processed/orders/"
    f"year={now.year}/month={now.month:02d}/"
)

logger.info(f"Writing parquet to: {output_path}")

(
    orders_processed
    .write
    .mode("overwrite")
    .parquet(output_path)
)

logger.info("ETL completed successfully")


# ── Glue Job commit ──────────────────────────────────────────
job.commit()