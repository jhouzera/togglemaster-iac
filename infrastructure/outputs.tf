# Fase atual: manter apenas saídas do bootstrap inicial (ECR).
# As saídas do cluster completo (VPC, EKS, RDS, Redis, IAM, IRSA, Secret Manager, etc.)
# ficam comentadas e serão reativadas quando a infraestrutura do cluster for provisionada.

output "ecr_repository_urls" {
  description = "ECR repository URLs for the initial bootstrap phase"
  value       = module.ecr.repository_urls
}

# output "vpc_id" {
#   description = "VPC ID"
#   value       = module.vpc.vpc_id
# }
#
# output "public_subnet_ids" {
#   description = "Public subnet IDs"
#   value       = module.vpc.public_subnet_ids
# }
#
# output "private_subnet_ids" {
#   description = "Private subnet IDs"
#   value       = module.vpc.private_subnet_ids
# }
#
# output "eks_cluster_name" {
#   description = "EKS cluster name"
#   value       = module.eks.cluster_name
# }
#
# output "eks_cluster_endpoint" {
#   description = "EKS API endpoint"
#   value       = module.eks.cluster_endpoint
# }
#
# output "eks_oidc_provider_arn" {
#   description = "EKS OIDC provider ARN"
#   value       = module.eks.oidc_provider_arn
# }
#
# output "auth_rds_endpoint" {
#   description = "RDS endpoint for auth service"
#   value       = module.data.auth_rds_endpoint
# }
#
# output "flag_rds_endpoint" {
#   description = "RDS endpoint for flag service"
#   value       = module.data.flag_rds_endpoint
# }
#
# output "targeting_rds_endpoint" {
#   description = "RDS endpoint for targeting service"
#   value       = module.data.targeting_rds_endpoint
# }
#
# output "redis_primary_endpoint" {
#   description = "ElastiCache Redis primary endpoint"
#   value       = module.data.redis_primary_endpoint
# }
#
# output "sqs_queue_arn" {
#   description = "SQS queue ARN"
#   value       = module.data.sqs_queue_arn
# }
#
# output "sqs_queue_url" {
#   description = "SQS queue URL"
#   value       = module.data.sqs_queue_url
# }
#
# output "dynamodb_table_name" {
#   description = "DynamoDB table name"
#   value       = module.data.dynamodb_table_name
# }
#
# output "keda_irsa_role_arn" {
#   description = "IAM Role ARN for KEDA via IRSA"
#   value       = module.iam.keda_irsa_role_arn
# }
#
# output "nginx_irsa_role_arn" {
#   description = "IAM Role ARN for ingress-nginx via IRSA"
#   value       = module.iam.nginx_irsa_role_arn
# }
#
# output "metrics_server_irsa_role_arn" {
#   description = "IAM Role ARN for metrics-server via IRSA"
#   value       = module.iam.metrics_server_irsa_role_arn
# }
#
# output "analytics_irsa_role_arn" {
#   description = "IAM Role ARN for analytics-service via IRSA"
#   value       = module.iam.analytics_irsa_role_arn
# }
#
# output "evaluation_irsa_role_arn" {
#   description = "IAM Role ARN for evaluation-service via IRSA"
#   value       = module.iam.evaluation_irsa_role_arn
# }
#
# output "eso_irsa_role_arn" {
#   description = "IAM Role ARN for External Secrets Operator via IRSA"
#   value       = module.iam.eso_irsa_role_arn
# }
#
