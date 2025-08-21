output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded CA certificate for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for the Medusa app image"
  value       = aws_ecr_repository.this.repository_url
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [for s in aws_subnet.private : s.id]
}