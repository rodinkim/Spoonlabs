output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_nodegroup_names" {
  description = "Names of the EKS node groups"
  value       = module.eks.eks_managed_node_groups
}

output "ecr_repository_url" {
  description = "ECR repository URL for Spring Boot image"
  value       = aws_ecr_repository.spring_app.repository_url
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_target_group_arn" {
  description = "ARN of the Application Load Balancer target group"
  value       = module.alb.target_group_arn
}