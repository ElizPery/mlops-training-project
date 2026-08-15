output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint Kubernetes API"
  value       = module.eks.cluster_endpoint
}

output "kubectl_config_command" {
  description = "Command for updating the local kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "node_groups" {
  description = "Node groups in the EKS cluster"
  value       = module.eks.eks_managed_node_groups
  sensitive   = true
}