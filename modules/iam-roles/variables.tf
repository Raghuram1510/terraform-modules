variable "cluster_name" {
  description = "Name of The cluster"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "role_name" {
  description = "Name of the role"
  type        = string
  default     = "ec2-role"
}

variable "role_type" {
  description = "Type: ec2, oidc, lambda, irsa, cross-account"
  type        = string
  default     = "ec2"

  validation {
    condition     = contains(["ec2", "oidc", "lambda", "irsa", "cross-account"], var.role_type)
    error_message = "Must be: ec2, oidc, lambda, irsa, or cross-account"
  }
}

variable "oidc_provider_url" {
  description = "OIDC provider (e.g., 'token.actions.githubusercontent.com')"
  type        = string
  default     = ""
}

variable "oidc_subject_claims" {
  description = "OIDC subject patterns (e.g., ['repo:myorg/myrepo:*'])"
  type        = list(string)
  default     = []
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN (for IRSA)"
  type        = string
  default     = ""
}

variable "k8s_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "k8s_service_account" {
  description = "Kubernetes ServiceAccount name"
  type        = string
  default     = ""
}

variable "trusted_account_ids" {
  description = "AWS account IDs allowed to assume this role"
  type        = list(string)
  default     = []
}

variable "external_id" {
  description = "External ID for secure cross-account access"
  type        = string
  default     = ""
}

variable "attach_eks_policies" {
  description = "Attach EKS worker Node attach_eks_policies"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Allow sending logs to cloudwatch"
  type        = bool
  default     = true
}

variable "custom_policy_arns" {
  description = "List of custom policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "create_instance_profile" {
  description = "Create EC2 instance profile (EC2 roles only)"
  type        = bool
  default     = true
}

variable "max_session_duration" {
  description = "Max credential validity (seconds: 3600-43200)"
  type        = number
  default     = 3600
}

variable "permissions_boundary_arn" {
  description = "Maximum permissions limit (policy ARN)"
  type        = string
  default     = ""
}

variable "path" {
  description = "IAM path (e.g., '/service-role/')"
  type        = string
  default     = "/"
}