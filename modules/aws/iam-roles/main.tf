# Get current AWS account information
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_trust" {
  count = var.role_type == "lambda" ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "oidc_trust" {
  count = var.role_type == "oidc" ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider_url}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${var.oidc_provider_url}:sub"
      values   = var.oidc_subject_claims
    }
  }
}

data "aws_iam_policy_document" "irsa_trust" {
  count = var.role_type == "irsa" ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "/^(.*:oidc-provider/)/", "")}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "/^(.*:oidc-provider/)/", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cross_account_trust" {
  count = var.role_type == "cross-account" ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        for account_id in var.trusted_account_ids :
        "arn:aws:iam::${account_id}:root"
      ]
    }

    dynamic "condition" {
      for_each = var.external_id != "" ? [1] : []

      content {
        test     = "StringEquals"
        variable = "sts:ExternalId"
        values   = [var.external_id]
      }
    }
  }
}

# Select appropriate trust policy based on role type
locals {
  trust_policy = (
    var.role_type == "ec2" ? data.aws_iam_policy_document.ec2_trust.json :
    var.role_type == "lambda" ? data.aws_iam_policy_document.lambda_trust[0].json :
    var.role_type == "oidc" ? data.aws_iam_policy_document.oidc_trust[0].json :
    var.role_type == "irsa" ? data.aws_iam_policy_document.irsa_trust[0].json :
    var.role_type == "cross-account" ? data.aws_iam_policy_document.cross_account_trust[0].json :
    data.aws_iam_policy_document.ec2_trust.json
  )
}

resource "aws_iam_role" "this" {
  name                 = "${var.cluster_name}-${var.environment}-${var.role_name}"
  assume_role_policy   = local.trust_policy
  max_session_duration = var.max_session_duration
  path                 = var.path
  permissions_boundary = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null

  tags = {
    Name        = "${var.cluster_name}-${var.environment}-${var.role_name}"
    Environment = var.environment
    RoleType    = var.role_type
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  count      = var.attach_eks_policies ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  count      = var.attach_eks_policies ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  count      = var.attach_eks_policies ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count      = var.enable_cloudwatch_logs ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "custom" {
  count      = length(var.custom_policy_arns)
  policy_arn = var.custom_policy_arns[count.index]
  role       = aws_iam_role.this.name
}

resource "aws_iam_instance_profile" "this" {
  count = var.role_type == "ec2" && var.create_instance_profile ? 1 : 0

  name = "${var.cluster_name}-${var.environment}-${var.role_name}"
  role = aws_iam_role.this.name
  path = var.path

  tags = {
    Name        = "${var.cluster_name}-${var.environment}-${var.role_name}"
    Environment = var.environment
  }
}

# Compliance test
