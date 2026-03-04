# EKS Cluster Configuration
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  create_iam_role = false
  iam_role_arn    = "arn:aws:iam::533267396259:role/my-terraform-eks-cluster-cluster-20260304123555128600000003"

# Disable encryption to avoid IAM policy creation/deletion
  create_kms_key = false
  cluster_encryption_config = {}

  # --- Network Configuration ---
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # --- Cluster Access ---

  enable_cluster_creator_admin_permissions = true

  # --- Cluster Networking ---
  cluster_endpoint_public_access = true

  # --- Worker Nodes ---
  eks_managed_node_groups = {
    general = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.medium"]
    }
  }
}