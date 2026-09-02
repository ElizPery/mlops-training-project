terraform {
  backend "s3" {
    bucket  = "mlops-tfstate-training"
    key     = "vpc/terraform.tfstate"
    region  = "us-east-1"
    profile = "devops-course"
  }
}