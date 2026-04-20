module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = [local.my_cidr]
  cluster_endpoint_private_access      = true

  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  node_group_min_size       = 1
  node_group_max_size       = 2
  node_group_desired_size   = 1
  node_group_instance_types = ["t3.medium"]
}
