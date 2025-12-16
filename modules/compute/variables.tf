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