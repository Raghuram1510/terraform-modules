variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "node_type" {
  description = "Worker or master"
  type        = string
  default     = "worker"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "subnet_id" {
  type = string
}

variable "iam_instance_profile" {
  type = string
}

variable "key_name" {
  description = "Key name for SSH"
  type        = string
  default     = ""
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "user_data_file" {
  description = "User data script(optional)"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID where the instance will be created"
  type        = string
}

variable "create_security_group" {
  description = "Create security group for the instance"
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "List of existing security group IDs (if create_security_group = false)"
  type        = list(string)
  default     = []
}

variable "security_group_name" {
  description = "Name for the security group (if created)"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into instances"
  type        = list(string)
  default     = []
}

variable "allowed_ingress_rules" {
  description = "Custom ingress rules for security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

# If true, allows unrestricted outbound traffic (dev / non-prod).
# If false, outbound traffic is restricted to allowed_egress_rules.


variable "allow_all_egress" {
  description = "Allow all outbound traffic. Set to true for dev/test, false for production."
  type        = bool
  default     = false # Secure by default (production setting)
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of root volume (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"
}

# Defines allowed outbound (egress) network access.
# Defaults to HTTPS-only to enforce least-privilege networking.
# Additional egress ports must be explicitly declared by the caller.
# Explicit allow-list for outbound traffic.
# Used only when allow_all_egress = false (recommended for prod).

variable "allowed_egress_rules" {
  description = "List of allowed egress rules when allow_all_egress is false"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS for package updates and API calls"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP for package repositories"
    }
  ]
}