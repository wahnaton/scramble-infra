resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  force = true

  data = {
    "mapRoles" = yamlencode(
      [
        {
          rolearn  = module.eks.eks_managed_node_group_roles["default"].arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups = [
            "system:bootstrappers",
            "system:nodes",
          ]
        },
        # This is the role running your Terraform
        {
          rolearn  = data.aws_caller_identity.current.arn
          username = "terraform-admin"
          groups = [
            "system:masters",
          ]
        },
      ]
    )
  }

  depends_on = [
    module.eks.cluster
  ]
}