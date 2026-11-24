output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_region" {
  description = "AWS region containing the EKS cluster."
  value       = var.aws_region
}

output "configure_kubectl" {
  description = "Command to configure kubectl for the new EKS cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "argocd_access" {
  description = "Command for accessing the Argo CD UI locally."
  value       = "kubectl port-forward svc/argocd-server -n argocd 8080:443"
}
