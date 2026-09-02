data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = "mlops-tfstate-training"
    key     = "vpc/terraform.tfstate"
    region  = "us-east-1"
    profile = "devops-course"
  }
}