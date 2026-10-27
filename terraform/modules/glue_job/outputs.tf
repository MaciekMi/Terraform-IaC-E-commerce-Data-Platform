output "job_name" {
  description = "Nazwa utworzonego Glue Joba"
  value       = aws_glue_job.this.name
}

output "job_arn" {
  description = "ARN utworzonego Glue Joba"
  value       = aws_glue_job.this.arn
}

output "role_arn" {
  description = "ARN roli IAM używanej przez Glue Job"
  value       = local.effective_role_arn
}

output "trigger_name" {
  description = "Nazwa Glue Trigger (pusta jeśli brak harmonogramu)"
  value       = var.schedule_expression != "" ? aws_glue_trigger.schedule[0].name : ""
}