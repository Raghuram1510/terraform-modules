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

variable "allow_all_egress" {
  description = "Allow all outbound traffic"
  type        = bool
  default     = true
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

