data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  user_data = var.user_data_file != "" ? file(var.user_data_file) : null
}

resource "aws_instance" "node" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids # ADDED
  iam_instance_profile   = var.iam_instance_profile
  key_name               = var.key_name != "" ? var.key_name : null

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "var.root_volume_type"
  }

  user_data = local.user_data

  tags = {
    Name        = "${var.cluster_name}-${var.environment}-${var.node_type}-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = var.security_group_name != "" ? var.security_group_name : "${var.cluster_name}-${var.environment}-${var.node_type}-sg"
  description = "Security group for ${var.cluster_name} ${var.node_type} instances"
  vpc_id      = var.vpc_id

  tags = {
    Name        = var.security_group_name != "" ? var.security_group_name : "${var.cluster_name}-${var.environment}-${var.node_type}-sg"
    Environment = var.environment
    NodeType    = var.node_type
  }
}


resource "aws_security_group_rule" "ssh" {
  count = var.create_security_group && length(var.allowed_ssh_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidr_blocks
  security_group_id = aws_security_group.this[0].id
  description       = "SSH access"
}


resource "aws_security_group_rule" "custom_ingress" {
  count = var.create_security_group ? length(var.allowed_ingress_rules) : 0

  type              = "ingress"
  from_port         = var.allowed_ingress_rules[count.index].from_port
  to_port           = var.allowed_ingress_rules[count.index].to_port
  protocol          = var.allowed_ingress_rules[count.index].protocol
  cidr_blocks       = var.allowed_ingress_rules[count.index].cidr_blocks
  security_group_id = aws_security_group.this[0].id
  description       = var.allowed_ingress_rules[count.index].description
}

resource "aws_security_group_rule" "egress" {
  count = var.create_security_group && var.allow_all_egress ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this[0].id
  description       = "Allow all outbound traffic"
}

# Compliance check
