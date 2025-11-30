# Outputs for EKS Cluster and VPC
output "cluster_name" { 
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
  
}
# Output the VPC ID
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}
# Output the EKS Cluster Endpoint
output "configure_kubectl" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

