variable "aws_region" {
  description = "AWS region dla wszystkich zasobów"
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = contains(["eu-central-1", "eu-west-1"], var.aws_region)
    error_message = "aws_region musi być jednym z obsługiwanych regionów: eu-central-1 lub eu-west-1."
  }
}

variable "project" {
  description = "Nazwa projektu używana w nazewnictwie zasobów"
  type        = string
  default     = "ecommerce"

  validation {
    condition     = length(var.project) >= 3
    error_message = "Nazwa projektu musi mieć co najmniej 3 znaki."
  }
}

variable "env" {
  description = "Środowisko (dev/staging/prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env musi być jednym z: dev, staging, prod."
  }
}

variable "db_username" {
  description = "Login do bazy RDS PostgreSQL"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_username) >= 3
    error_message = "db_username musi mieć co najmniej 3 znaki."
  }
}

variable "db_password" {
  description = "Hasło do bazy RDS PostgreSQL"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "db_password musi mieć co najmniej 8 znaków."
  }
}

variable "vpc_id" {
  description = "ID VPC, w którym zostanie wdrożony RDS"
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "vpc_id musi być poprawnym ID VPC zaczynającym się od 'vpc-'."
  }
}

variable "private_subnet_ids" {
  description = "Lista ID prywatnych podsieci dla RDS Subnet Group"
  type        = list(string)

  validation {
    condition = (
      length(var.private_subnet_ids) >= 2 &&
      alltrue([
        for subnet_id in var.private_subnet_ids :
        can(regex("^subnet-", subnet_id))
      ])
    )
    error_message = "Podaj co najmniej 2 poprawne ID podsieci zaczynające się od 'subnet-'."
  }
}