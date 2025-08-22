module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = var.cluster_name
  cluster_version                = "1.29"
  vpc_id                         = aws_vpc.this.id
  subnet_ids                     = [for s in aws_subnet.private : s.id]
  enable_irsa                    = true
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = [var.instance_type]
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      subnet_ids     = [aws_subnet.private[0].id]
    }
  }
}