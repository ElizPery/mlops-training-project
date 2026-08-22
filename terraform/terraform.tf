terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }

  backend "s3" {
    bucket  = "mlops-tfstate-training"
    key     = "step-function/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    profile = "devops-course"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "mlops-course"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
