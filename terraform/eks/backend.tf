terraform {
  backend "s3" {
    bucket  = "mlops-tfstate-training"
    key     = "eks/terraform.tfstate"
    region  = "us-east-1"
    profile = "devops-course"
  }
}