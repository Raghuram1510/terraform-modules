variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name(dev/staging/prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support for the VPC"
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "azs_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "create_public_subnets" {
  description = "Create public subnets"
  type        = bool
  default     = true
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = []
}

variable "public_subnet_suffix" {
  description = "Suffix for public subnet names"
  type        = string
  default     = "public"
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs in public subnets"
  type        = bool
  default     = true
}

variable "create_private_subnets" {
  description = "Create private subnets"
  type        = bool
  default     = true
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_suffix" {
  description = "Suffix for private subnet names"
  type        = string
  default     = "private"
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnets"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for all private subnets"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Create one NAT gateway per availability zone"
  type        = bool
  default     = false
}

variable "create_igw" {
  description = "Create internet gateway"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable flow logs"
  type        = bool
  default     = false
}

variable "flow_log_destination" {
  description = "Destination for flow logs (e.g., CloudWatch Logs, S3)"
  type        = string
  default     = "cloudwatch"
}

variable "tags" {
  description = "Tags to apply to all VPC resources"
  type        = map(string)
  default     = {}
}

variable "enable_s3_endpoint" {
  description = "Create VPC endpoint for S3 (saves NAT costs)"
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "Create VPC endpoint for DynamoDB (saves NAT costs)"
  type        = bool
  default     = false
}