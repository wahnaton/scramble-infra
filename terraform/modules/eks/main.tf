module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = [var.instance_type]
      desired_size   = 1
      max_size       = 2
      min_size       = 1
    }
  }

  tags = var.tags
}