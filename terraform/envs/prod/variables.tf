variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "scramble-store-api-cluster"
}

variable "instance_type" {
  description = "EC2 instance type for EKS node group"
  type        = string
  default     = "t4g.small"
}

variable "ami_type" {
  description = "AMI type for the managed node group"
  type        = string
  default     = "AL2_ARM_64"
}