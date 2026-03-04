# EKS Cluster Configuration
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  create_iam_role = true
  
  create_kms_key            = true

  # --- CloudWatch Log Group ---
  create_cloudwatch_log_group = true
  cluster_enabled_log_types   = ["api", "audit", "authenticator"]

  # --- Network Configuration ---
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # --- Cluster Access ---

  enable_cluster_creator_admin_permissions = true

  # --- Cluster Networking ---
  cluster_endpoint_public_access = true
  cluster_endpoint_public_access_cidrs = [local.my_cidr]
  cluster_endpoint_private_access      = true
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