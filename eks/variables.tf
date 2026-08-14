variable "aws_region" {
  default     = "us-east-1"
  description = "Default Region"
}

variable "environment" {
  description = "Назва середовища"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Назва EKS кластера"
  type        = string
  default     = "mlops-eks-cluster"
}

variable "cluster_version" {
  description = "Версія Kubernetes"
  type        = string
  default     = "1.30"
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
  default     = 2
}

variable "cpu_nodes_min" {
  description = "Minimum number of CPU nodes"
  default     = 1
}

variable "cpu_nodes_max" {
  description = "Maximum number of CPU nodes"
  default     = 3
}

variable "gpu_nodes_desired" {
  description = "Desired number of GPU nodes"
  default     = 1
}

variable "gpu_nodes_min" {
  description = "Minimum number of GPU nodes"
  default     = 0
}

variable "gpu_nodes_max" {
  description = "Maximum number of GPU nodes"
  default     = 2
}