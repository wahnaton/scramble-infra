data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com"
  ]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

data "aws_iam_policy_document" "gh_actions_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:playscramblegame/*:ref:refs/heads/main",
        "repo:playscramblegame/*:ref:refs/tags/*",
        "repo:playscramblegame/*:environment:prod"
      ]
    }
  }
}

resource "aws_iam_role" "gh_deploy" {
  name               = "${var.cluster_name}-gh-deploy"
  assume_role_policy = data.aws_iam_policy_document.gh_actions_assume.json
}

# ECR push permissions limited to the app repository
data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid    = "AuthToken"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "PushPullRepo"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories",
      "ecr:ListImages"
    ]
    resources = [aws_ecr_repository.this.arn]
  }
}

resource "aws_iam_policy" "ecr_push" {
  name   = "${var.cluster_name}-ecr-push"
  policy = data.aws_iam_policy_document.ecr_push.json
}

# Minimal EKS permissions to fetch cluster details for kubeconfig/token
data "aws_iam_policy_document" "eks_describe" {
  statement {
    effect  = "Allow"
    actions = ["eks:DescribeCluster"]
    resources = [
      "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
    ]
  }
}

resource "aws_iam_policy" "eks_describe" {
  name   = "${var.cluster_name}-eks-describe"
  policy = data.aws_iam_policy_document.eks_describe.json
}

resource "aws_iam_role_policy_attachment" "gh_attach_ecr" {
  role       = aws_iam_role.gh_deploy.name
  policy_arn = aws_iam_policy.ecr_push.arn
}

resource "aws_iam_role_policy_attachment" "gh_attach_eks" {
  role       = aws_iam_role.gh_deploy.name
  policy_arn = aws_iam_policy.eks_describe.arn
}