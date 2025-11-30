# outputs.tf
output "cluster_name" { 
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
  
}

output "kubeconfig" {
  description = "Kubeconfig file content to access the EKS cluster"
  value       = module.eks.kubeconfig
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "configure_kubectl" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

