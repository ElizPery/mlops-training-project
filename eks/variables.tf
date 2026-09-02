variable "aws_region" {
  default     = "us-east-1"
  description = "Default Region"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "mlops-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "cpu_node_instance_type" {
  description = "EC2 instance type for CPU worker nodes"
  type        = string
  default     = "t3.small"
}

variable "gpu_node_instance_type" {
  description = "EC2 instance type for GPU worker nodes"
  type        = string
  default     = "t3.small"
}

variable "cpu_nodes_desired" {
  description = "Desired number of CPU nodes"
  default     = 4
}

variable "cpu_nodes_min" {
  description = "Minimum number of CPU nodes"
  default     = 1
}

variable "cpu_nodes_max" {
  description = "Maximum number of CPU nodes"
  default     = 4
}

variable "gpu_nodes_desired" {
  description = "Desired number of GPU nodes"
  default     = 0
}

variable "gpu_nodes_min" {
  description = "Minimum number of GPU nodes"
  default     = 0
}

variable "gpu_nodes_max" {
  description = "Maximum number of GPU nodes"
  default     = 2
}