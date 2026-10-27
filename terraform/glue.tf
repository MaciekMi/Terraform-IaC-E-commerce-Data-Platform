resource "aws_s3_object" "orders_script" {
  bucket = aws_s3_bucket.raw.id
  key    = "glue_scripts/orders_etl.py"
  source = "../glue_scripts/orders_etl.py"
  etag   = filemd5("../glue_scripts/orders_etl.py")
}

module "orders_etl" {
  source = "./modules/glue_job"

  name           = "orders"
  scripts_bucket = aws_s3_bucket.raw.id
  source_bucket  = aws_s3_bucket.raw.id
  target_bucket  = aws_s3_bucket.processed.id

  create_role   = false
  glue_role_arn = aws_iam_role.glue.arn

  tags = local.common_tags

  depends_on = [
    aws_s3_object.orders_script
  ]
}