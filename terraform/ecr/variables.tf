variable "ecr_name" {
  description = "The name of the ECR repository to create"
  type        = string
  default     = "inference-service"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned on push or not"
  type        = bool
  default     = true
}