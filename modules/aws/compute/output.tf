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

output "security_group_id" {
  description = "ID of the created security group (if created)"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}
output "security_group_name" {
  description = "Name of the created security group (if created)"
  value       = var.create_security_group ? aws_security_group.this[0].name : null
}
output "instance_names" {
  description = "Names of created instances"
  value       = aws_instance.node[*].tags.Name
}
output "instance_availability_zones" {
  description = "Availability zones where instances are running"
  value       = aws_instance.node[*].availability_zone
}
output "instance_arns" {
  description = "ARNs of EC2 instances"
  value       = aws_instance.node[*].arn
}