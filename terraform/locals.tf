locals {
  # Spójny prefix nazewnictwa zasobów
  name_prefix = "${var.project}-${var.env}"

  # Wspólne tagi dla zasobów AWS
  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
    Owner       = "data-engineering"
    CostCenter  = "data-platform"
  }

  # Konfiguracja zależna od środowiska
  environment_config = {
    dev = {
      rds_instance_class    = "db.t3.micro"
      rds_allocated_storage = 20
      rds_backup_retention  = 1
    }

    staging = {
      rds_instance_class    = "db.t3.micro"
      rds_allocated_storage = 20
      rds_backup_retention  = 3
    }

    prod = {
      rds_instance_class    = "db.t3.small"
      rds_allocated_storage = 100
      rds_backup_retention  = 7
    }
  }

  # Konfiguracja dla aktualnie wybranego środowiska
  env_config = local.environment_config[var.env]
}