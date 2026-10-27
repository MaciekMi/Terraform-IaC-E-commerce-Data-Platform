variable "name" {
  description = "Suffix nazwy Glue Joba (np. 'orders', 'customers')"
  type        = string
}

variable "scripts_bucket" {
  description = "Bucket S3 z uploadowanymi skryptami Glue"
  type        = string
}

variable "source_bucket" {
  description = "Bucket S3 z danymi wejściowymi (raw)"
  type        = string
}

variable "target_bucket" {
  description = "Bucket S3 na dane wyjściowe (processed)"
  type        = string
}

variable "glue_role_arn" {
  description = "ARN roli IAM dla Glue. Pusta = moduł tworzy rolę automatycznie"
  type        = string
  default     = ""
}

variable "glue_version" {
  description = "Wersja AWS Glue"
  type        = string
  default     = "4.0"
}

variable "worker_type" {
  description = "Typ workera"
  type        = string
  default     = "G.1X"
}

variable "number_of_workers" {
  description = "Liczba workerów Spark"
  type        = number
  default     = 2
}

variable "timeout_minutes" {
  description = "Maksymalny czas wykonania joba w minutach"
  type        = number
  default     = 60
}

variable "max_retries" {
  description = "Liczba prób ponowienia przy błędzie"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tagi przypisywane do wszystkich zasobów modułu"
  type        = map(string)
  default     = {}
}

variable "schedule_expression" {
  description = "Wyrażenie CRON dla harmonogramu Glue Trigger. Puste = brak triggera."
  type        = string
  default     = ""
}

variable "create_role" {
  description = "Czy moduł ma utworzyć własną rolę IAM dla Glue"
  type        = bool
  default     = true
}