# helm.tf

# ==============================================================================
# AWS Load Balancer Controller (Existing Configuration)
# ==============================================================================

# 1. Download the IAM policy document for the AWS Load Balancer Controller
data "http" "aws_load_balancer_controller_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
}

# 2. Create the IAM policy using the downloaded document
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.cluster_name}-aws-load-balancer-controller-policy"
  description = "IAM policy for the AWS Load Balancer Controller"
  policy      = data.http.aws_load_balancer_controller_iam_policy.response_body
}

# 3. Create the IAM Role and Service Account for the controller (IRSA)
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name                              = "${var.cluster_name}-alb-controller-role"
  attach_load_balancer_controller_policy = false # We are attaching our own policy from the URL above

  role_policy_arns = {
    policy = aws_iam_policy.aws_load_balancer_controller.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# 4. Deploy the AWS Load Balancer Controller using the Helm chart
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa.iam_role_arn
  }

  depends_on = [
    module.eks.cluster,
    module.eks.eks_managed_node_group,
    module.aws_load_balancer_controller_irsa
  ]
}


# ==============================================================================
# External Secrets Operator (for AWS SSM Parameter Store)
# ==============================================================================

# 5. Define the IAM policy for the External Secrets Operator
data "aws_iam_policy_document" "external_secrets" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = [
      # IMPORTANT: For better security, restrict this to specific parameter paths
      # Example: "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/my-app/*"
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/*"
    ]
    effect = "Allow"
  }
}

# 6. Create the IAM policy from the document
resource "aws_iam_policy" "external_secrets" {
  name   = "${var.cluster_name}-external-secrets-policy"
  policy = data.aws_iam_policy_document.external_secrets.json
}

# 7. Create the IAM Role and Service Account for the operator (IRSA)
module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = "${var.cluster_name}-external-secrets-role"

  role_policy_arns = {
    policy = aws_iam_policy.external_secrets.arn
  }

  oidc_providers = {
    main = {
      provider_arn = module.eks.oidc_provider_arn
      # The namespace and service account name are defaults from the Helm chart
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }
}

# 8. Deploy the External Secrets Operator using the Helm chart
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = "0.9.13" # Pin to a specific, stable version

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_secrets_irsa.iam_role_arn
  }

  # Ensure the EKS cluster is ready before installing
  depends_on = [
    module.eks.cluster,
    module.eks.eks_managed_node_group,
    module.external_secrets_irsa
  ]
}

# Helper data source to get current AWS account ID for IAM policy
data "aws_caller_identity" "current" {}
