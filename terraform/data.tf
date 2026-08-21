terraform {
  backend "s3" {
    bucket  = "mlops-tfstate-training"
    key     = "step-function/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    profile = "devops-course"
  }
}

data "aws_iam_policy_document" "stepfunction_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "archive_file" "validate" {
  type        = "zip"
  source_file = "${path.module}/lambda/validate.py"
  output_path = "${path.module}/lambda/validate.zip"
}

data "archive_file" "log_metrics" {
  type        = "zip"
  source_file = "${path.module}/lambda/log_metrics.py"
  output_path = "${path.module}/lambda/log_metrics.zip"
}

