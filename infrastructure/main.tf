# Fase atual: manter a infraestrutura pronta para futura expansão, mas NÃO criar os
# recursos abaixo neste momento. Esses módulos serão ativados em uma etapa posterior,
# quando o objetivo for provisionar o cluster completo (VPC, EKS, dados, IAM e ArgoCD).
#
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  use_nat_gateway      = var.use_nat_gateway
}

module "eks" {
  source = "./modules/eks"

  project_name                     = var.project_name
  environment                      = var.environment
  cluster_version                  = var.eks_cluster_version
  subnet_ids                       = module.vpc.private_subnet_ids
  vpc_id                           = module.vpc.vpc_id
  endpoint_public_access           = var.eks_endpoint_public_access
  endpoint_private_access          = var.eks_endpoint_private_access
  public_access_cidrs              = var.eks_public_access_cidrs
  node_instance_type               = var.node_instance_type
  node_desired_size                = var.node_desired_size
  node_min_size                    = var.node_min_size
  node_max_size                    = var.node_max_size
  lab_role_arn                     = var.lab_role_arn
  eks_admin_trusted_principal_arns = var.eks_admin_trusted_principal_arns
}

module "data" {
  source = "./modules/data"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_username        = var.db_username
  db_password        = var.db_password
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source = "./modules/iam"

  project_name                    = var.project_name
  environment                     = var.environment
  oidc_provider_arn               = module.eks.oidc_provider_arn
  oidc_provider_url               = module.eks.oidc_provider_url
  sqs_queue_arn                   = module.data.sqs_queue_arn
  dynamodb_table_arn              = module.data.dynamodb_table_arn
  keda_namespace                  = var.keda_namespace
  keda_service_account_name       = var.keda_service_account_name
  nginx_namespace                 = var.nginx_namespace
  nginx_service_account_name      = var.nginx_service_account_name
  metrics_namespace               = var.metrics_namespace
  metrics_service_account_name    = var.metrics_service_account_name
  analytics_namespace             = var.analytics_namespace
  analytics_service_account_name  = var.analytics_service_account_name
  evaluation_namespace            = var.evaluation_namespace
  evaluation_service_account_name = var.evaluation_service_account_name
  eso_namespace                   = var.eso_namespace
  eso_service_account_name        = var.eso_service_account_name
  ecr_repository_prefix           = "${var.project_name}-${var.environment}"
}

# module "argocd" {
#   source = "./modules/argocd"

#   project_name    = var.project_name
#   environment     = var.environment
#   gitops_repo_url = var.togglemaster_gitops_repo_url
#   gitops_branch   = var.togglemaster_gitops_branch

#   depends_on = [module.eks]
# }
