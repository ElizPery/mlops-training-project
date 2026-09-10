output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.inference_service.repository_url
}

output "ecr_repository_arn" {
  value       = aws_ecr_repository.inference_service.arn # або назва вашого ресурсу ecr
  description = "The ARN of the ECR repository"
}