data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "aws_eks_cluster" "this" {
  name     = "${var.cluster_name}-${var.environment}"
  version  = var.kubernetes_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = var.cluster_security_group_ids
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  tags = merge(
    {
      Name        = "${var.cluster_name}-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Compliance  = "HIPAA,SOC2,CIS"
    },
    var.tags,
    var.cluster_tags
  )

  depends_on = [aws_cloudwatch_log_group.eks]
}

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true # CIS requirement
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
  tags = {
    Name        = "${var.cluster_name}-${var.environment}-eks-key"
    Environment = var.environment
    Compliance  = "HIPAA,SOC2,CIS"
  }
}


resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id

  # Note: aws_kms_alias doesn't support tags - this is a Checkov false positive
  # KMS aliases inherit permissions from their target key
}

# COMPLIANCE: Audit logging for HIPAA/SOC2
# Only created if logging is enabled

resource "aws_cloudwatch_log_group" "eks" {
  count             = length(var.enabled_cluster_log_types) > 0 ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}-${var.environment}/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.eks.arn # <-- ADD THIS LINE

  tags = {
    Name        = "${var.cluster_name}-${var.environment}-eks-logs"
    Environment = var.environment
    Compliance  = "HIPAA,SOC2,CIS"
  }
}

# Enables pods to assume IAM roles securely
# Required for: Crossplane, ArgoCD, AWS LB Controller

data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  tags = {
    Name        = "${var.cluster_name}-${var.environment}-oidc"
    Environment = var.environment
    Compliance  = "HIPAA,SOC2,CIS"
  }
}

# Only created if enable_managed_node_group = true
# Alternative: Use your Compute module for self-managed nodes
resource "aws_eks_node_group" "this" {
  count           = var.enable_managed_node_group ? 1 : 0
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-${var.environment}-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.node_instance_types
  disk_size       = var.node_disk_size
  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }
  # COMPLIANCE: Use latest AMI with security patches
  ami_type = "AL2_x86_64"
  # COMPLIANCE: Force IMDSv2 (prevents SSRF attacks)
  launch_template {
    id      = aws_launch_template.eks_nodes[0].id
    version = aws_launch_template.eks_nodes[0].latest_version
  }
  tags = merge(
    {
      Name        = "${var.cluster_name}-${var.environment}-nodes"
      Environment = var.environment
      Compliance  = "HIPAA,SOC2,CIS"
    },
    var.tags,
    var.node_group_tags
  )
  depends_on = [aws_eks_cluster.this]
}

# HIPAA/CIS: Enforce IMDSv2 to prevent SSRF credential theft
resource "aws_launch_template" "eks_nodes" {
  count = var.enable_managed_node_group ? 1 : 0
  name  = "${var.cluster_name}-${var.environment}-eks-nodes"
  # COMPLIANCE: Enforce IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Forces IMDSv2
    http_put_response_hop_limit = 1
  }
  # COMPLIANCE: Encrypted root volume
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.cluster_name}-${var.environment}-node"
      Environment = var.environment
      Compliance  = "HIPAA,SOC2,CIS"
    }
  }
}

# Only needed if using Compute module (self-managed nodes)
# Allows communication between control plane and workers
resource "aws_security_group" "node" {
  count       = var.enable_managed_node_group ? 0 : 1
  name        = "${var.cluster_name}-${var.environment}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id
  tags = {
    Name                                                           = "${var.cluster_name}-${var.environment}-node-sg"
    Environment                                                    = var.environment
    Compliance                                                     = "HIPAA,SOC2,CIS"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "owned"
  }
}
# Allow nodes to communicate with each other
resource "aws_security_group_rule" "node_to_node" {
  count                    = var.enable_managed_node_group ? 0 : 1
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.node[0].id
  source_security_group_id = aws_security_group.node[0].id
  description              = "Node to node communication"
}
# Allow control plane to communicate with nodes
resource "aws_security_group_rule" "control_plane_to_node" {
  count                    = var.enable_managed_node_group ? 0 : 1
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node[0].id
  source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description              = "Control plane to nodes (HTTPS)"
}
resource "aws_security_group_rule" "control_plane_to_node_kubelet" {
  count                    = var.enable_managed_node_group ? 0 : 1
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node[0].id
  source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description              = "Control plane to kubelet"
}
# Allow nodes to reach control plane
resource "aws_security_group_rule" "node_to_control_plane" {
  count                    = var.enable_managed_node_group ? 0 : 1
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.node[0].id
  description              = "Nodes to control plane"
}
# Allow all outbound (nodes need internet for ECR, etc.)
resource "aws_security_group_rule" "node_egress" {
  count             = var.enable_managed_node_group ? 0 : 1
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node[0].id
  description       = "Allow all outbound"
}
