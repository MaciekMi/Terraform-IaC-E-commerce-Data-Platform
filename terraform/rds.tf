data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "PostgreSQL access only from VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${local.name_prefix}-postgres-params"
  family = "postgres15"

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  tags = {
    Name = "${local.name_prefix}-postgres-params"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "${local.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = "15.19"

  instance_class        = local.env_config.rds_instance_class
  allocated_storage     = local.env_config.rds_allocated_storage
  max_allocated_storage = 100

  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "ecommerce"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  db_subnet_group_name = aws_db_subnet_group.main.name
  parameter_group_name = aws_db_parameter_group.postgres.name

  backup_retention_period = local.env_config.rds_backup_retention

  backup_window      = "03:00-04:00"
  maintenance_window = "Mon:04:00-Mon:05:00"

  publicly_accessible = false

  deletion_protection = var.env == "prod" ? true : false

  skip_final_snapshot = var.env == "prod" ? false : true

  final_snapshot_identifier = "${local.name_prefix}-final-snapshot"

  tags = {
    Name = "${local.name_prefix}-postgres"
  }
}