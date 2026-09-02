variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "devops-course"
}

variable "aws_region" {
  description = "AWS region for AWS provider (need to match the EKS region)"
  type        = string
  default     = "us-east-1"
}

variable "eks_state_bucket" {
  description = "S3 bucket for remote state EKS"
  type        = string
  default     = "mlops-tfstate-training"
}

variable "eks_state_key" {
  description = "S3 key for remote state EKS"
  type        = string
  default     = "eks/terraform.tfstate"
}

variable "eks_state_region" {
  description = "Region of bucket with EKS remote state"
  type        = string
  default     = "us-east-1"
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "infra-tools"
}

variable "argocd_chart_version" {
  description = "Version of Helm chart for Argo CD"
  type        = string
  default     = "7.7.5"
}

variable "app_repo_url" {
  description = "Public Git repository with manifests"
  type        = string
  default     = "https://github.com/ElizPery/mlops-training-project-manifests.git"
}

variable "app_repo_branch" {
  description = "Branch"
  type        = string
  default     = "lesson-9"
}
