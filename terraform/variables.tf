variable "aws_region" {
  default     = "us-east-1"
  description = "Default Region"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "devops-course"
}

variable "project_name" {
  type        = string
  default     = "mlops-train"
  description = "Project name prefix to prevent resource naming collisions"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name"
}

variable "lambda_validate_zip" {
  description = "Relative path to validate lambda zip file"
  type        = string
  default     = "lambda/validate.zip"
}

variable "lambda_log_metrics_zip" {
  description = "Relative path to log metrics lambda zip file"
  type        = string
  default     = "lambda/log_metrics.zip"
}
