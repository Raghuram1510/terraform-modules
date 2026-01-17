output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded cluster CA certificate"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = aws_eks_cluster.this.version
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
  # Used by: IAM module with role_type = "irsa"
}

output "oidc_provider_url" {
  description = "OIDC provider URL (without https://)"
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID for self-managed nodes"
  value       = var.enable_managed_node_group ? null : aws_security_group.node[0].id
}

output "node_group_id" {
  description = "Managed node group ID"
  value       = var.enable_managed_node_group ? aws_eks_node_group.this[0].id : null
}

output "node_group_status" {
  description = "Managed node group status"
  value       = var.enable_managed_node_group ? aws_eks_node_group.this[0].status : null
}

output "kubeconfig_command" {
  description = "AWS CLI command to update kubeconfig"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${data.aws_region.current.name}"
}

output "bootstrap_user_data" {
  description = "Base64 encoded user data for self-managed nodes"
  value = base64encode(templatefile("${path.module}/templates/bootstrap.sh", {
    cluster_name     = aws_eks_cluster.this.name
    cluster_endpoint = aws_eks_cluster.this.endpoint
    cluster_ca       = aws_eks_cluster.this.certificate_authority[0].data
  }))
}
