# Configure the Kubernetes provider to use the EKS cluster
data "aws_eks_cluster" "eks_cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks.cluster_name]
}

# Get authentication token for the EKS cluster
data "aws_eks_cluster_auth" "eks_cluster" {
  name = module.eks.cluster_name
}
# Configure the Kubernetes provider to use the EKS cluster
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
}



