terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "ecommerce-tf-state-394281571971-eu-central-1"
    key            = "ecommerce/dev/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "ecommerce-dev"

  default_tags {
    tags = local.common_tags
  }
}