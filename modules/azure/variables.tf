variable "vnet_name" {
    description = "Name prefix for the virtual network (like vpc_name in AWS)"
    type        = string
}

variable "environment" {
    description = "Environment (dev, staging, prod)"
    type        = string
}

variable "location" {
    description = "Azure region (like AWS region: us-east-1 = eastus)"
    type        = string
    default     = "eastus"
}

variable "create_resource_group" {
    description = "Create a new resource group or use existing"
    type        = bool
    default     = true
}

