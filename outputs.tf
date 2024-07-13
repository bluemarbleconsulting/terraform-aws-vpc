output "private_subnet_ids" {
  description = "The IDs of the private subnets of the VPC"
  value       = toset(aws_subnet.private[*].id)
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets of the VPC"
  value       = toset(aws_subnet.public[*].id)
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}
