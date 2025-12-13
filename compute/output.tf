output "instance_ids" {
  description = "List of instance IDs"
  value       = aws_instance.node[*].id
}

output "private_ips" {
  description = "Private IP addresses"
  value       = aws_instance.node[*].private_ip
}

output "public_ips" {
  description = "Public IP addresses"
  value       = aws_instance.node[*].public_ip
}