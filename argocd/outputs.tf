output "argocd_namespace" {
  description = "Namespace, where Argo CD is deployed"
  value       = var.argocd_namespace
}

output "argocd_get_initial_password_command" {
  description = "Command to get the initial admin password for Argo CD"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d; echo"
}

output "argocd_ui_port_forward_command" {
  description = "Command to forward port to Argo CD UI"
  value       = "kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:80"
}

output "demo_app_port_forward_command" {
  description = "Command to check the working demo application"
  value       = "kubectl -n application port-forward deployment/demo-nginx 8081:80"
}