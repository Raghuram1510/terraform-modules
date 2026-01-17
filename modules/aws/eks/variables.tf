variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
  # Comes from: module.vpc.vpc_id
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
  # Comes from: module.vpc.private_subnet_ids
}

variable "cluster_role_arn" {
  description = "IAM role ARN for EKS control plane"
  type        = string
  # Comes from: module.eks_cluster_role.role_arn
  # This role allows EKS to manage AWS resources
}

variable "node_role_arn" {
  description = "IAM role ARN for worker nodes (managed or self-managed)"
  type        = string
  default     = ""
  # For managed nodes: passed to aws_eks_node_group
  # For self-managed: same role, but use instance_profile_name in Compute module
}

variable "enable_managed_node_group" {
  description = "Create AWS managed node group(vs self-managed)"
  type        = bool
  default     = false
  # false = Use Compute module for workers (more control)
  # true  = EKS creates and manages nodes (simpler)
}

variable "node_instance_types" {
  description = "Instance types for managed node group"
  type        = list(string)
  default     = ["m7i-flex.large"]
  # m7i-flex.large = 2 vCPU, 8 GB RAM 
  # Free tier options: ["t2.micro"], ["t3.micro"], ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Disk size in GB for MANAGED node groups only"
  type        = number
  default     = 20
  # Only used when enable_managed_node_group = true
  # For self-managed: use root_volume_size in Compute module
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.32"
  # Supported: 1.29, 1.30, 1.31, 1.32, 1.33, 1.34
  # Recommend: Use latest stable (1.32+) for new clusters
}


variable "enabled_cluster_log_types" {
  description = "Control plane log types to enable"
  type        = list(string)
  default     = []
  # Free tier: [] (saves CloudWatch costs)
  # Production: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
  # Free tier: 7 (minimum)
  # Production: 90 or 365
}

variable "enable_cluster_autoscaler" {
  description = "Install Cluster Autoscaler (traditional Kubernetes way)"
  type        = bool
  default     = false
  # Scales nodes based on pending pods
  # Works with: Managed Node Groups or self-managed with ASG
}

variable "enable_karpenter" {
  description = "Install Karpenter (modern, recommended)"
  type        = bool
  default     = false
  # Fast, cost-optimized, can scale to zero
  # Creates its own nodes (no node groups needed)
}

variable "enable_asg_scaling" {
  description = "Enable ASG scaling policies for self-managed nodes"
  type        = bool
  default     = false
  # Traditional AWS Auto Scaling
  # Only for self-managed nodes using Compute module
}

variable "endpoint_private_access" {
  description = "Enable private API endpoint (access from within VPC)"
  type        = bool
  default     = true
  # true = kubectl works from within VPC
  # Required for private subnets
}

variable "endpoint_public_access" {
  description = "Enable public API endpoint (access from internet)"
  type        = bool
  default     = true
  # true = kubectl works from your laptop
  # Production: set false and use VPN/bastion
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  # Production: restrict to your IP ["YOUR.IP.ADDRESS/32"]
}

variable "tags" {
  description = "Tags to apply to all EKS resources"
  type        = map(string)
  default     = {}
  # Example: { "Project" = "MyApp", "CostCenter" = "Engineering" }
}

variable "cluster_tags" {
  description = "Additional tags for the EKS cluster only"
  type        = map(string)
  default     = {}
}

variable "node_group_tags" {
  description = "Additional tags for managed node groups only"
  type        = map(string)
  default     = {}
}

variable "cluster_security_group_ids" {
  description = "Additional security groups for the EKS cluster"
  type        = list(string)
  default     = []
  # EKS creates its own SG, but you can add more
}