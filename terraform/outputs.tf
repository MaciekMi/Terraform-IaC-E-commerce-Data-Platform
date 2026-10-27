output "raw_bucket_name" {
  description = "Nazwa bucketa S3 RAW"
  value       = aws_s3_bucket.raw.id
}

output "processed_bucket_name" {
  description = "Nazwa bucketa S3 PROCESSED"
  value       = aws_s3_bucket.processed.id
}

output "curated_bucket_name" {
  description = "Nazwa bucketa S3 CURATED"
  value       = aws_s3_bucket.curated.id
}

output "rds_endpoint" {
  description = "Endpoint bazy PostgreSQL RDS"
  value       = aws_db_instance.postgres.endpoint
}

output "orders_etl_job_name" {
  description = "Nazwa AWS Glue Job"
  value       = module.orders_etl.job_name
}

output "glue_role_arn" {
  description = "ARN roli IAM używanej przez AWS Glue"
  value       = aws_iam_role.glue.arn
}