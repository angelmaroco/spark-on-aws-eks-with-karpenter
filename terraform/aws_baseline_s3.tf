module "aws_baseline_s3_spark" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.44.0"

  block_public_acls       = var.aws_baseline_s3_spark.block_public_acls
  block_public_policy     = var.aws_baseline_s3_spark.block_public_policy
  bucket_name             = var.aws_baseline_s3_spark.bucket_name
  enabled                 = var.aws_baseline_s3_spark.create_s3_bucket
  force_destroy           = var.aws_baseline_s3_spark.force_destroy
  restrict_public_buckets = var.aws_baseline_s3_spark.restrict_public_buckets
  sse_algorithm           = var.aws_baseline_s3_spark.sse_algorithm
  versioning_enabled      = var.aws_baseline_s3_spark.versioning
  tags                    = var.tags
}

resource "aws_s3_bucket_object" "spark_ui_path" {
  bucket = module.aws_baseline_s3_spark.bucket_id
  acl    = "private"
  key    = var.aws_baseline_s3_spark.spark_ui_path
  source = "/dev/null"
}

resource "aws_s3_bucket_object" "spark_data_path" {
  bucket = module.aws_baseline_s3_spark.bucket_id
  acl    = "private"
  key    = var.aws_baseline_s3_spark.spark_data_path
  source = "/dev/null"
}