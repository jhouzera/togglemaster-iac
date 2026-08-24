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

  project_name       = var.project_name
  environment        = var.environment
  cluster_version    = var.eks_cluster_version
  subnet_ids         = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  lab_role_arn       = var.lab_role_arn
}

module "data" {
  source = "./modules/data"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_username        = var.db_username
  db_password        = var.db_password
  service_api_key    = var.service_api_key
  master_key         = var.master_key
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
  secrets_manager_arns            = module.data.secrets_manager_arns
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

resource "null_resource" "argocd_bootstrap" {
  triggers = {
    cluster_name         = module.eks.cluster_name
    cluster_endpoint     = module.eks.cluster_endpoint
    gitops_repo_url      = var.togglemaster_gitops_repo_url
    gitops_branch        = var.togglemaster_gitops_branch
    addons_repo_url      = var.togglemaster_addons_repo_url
    addons_branch        = var.togglemaster_addons_branch
    argocd_namespace     = var.argocd_namespace
    argocd_chart_version = var.argocd_chart_version
  }

  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "${path.module}/scripts/bootstrap-argocd.sh"

    environment = {
      AWS_REGION           = var.aws_region
      TF_AWS_PROFILE       = var.aws_profile
      CLUSTER_NAME         = module.eks.cluster_name
      ARGOCD_NAMESPACE     = var.argocd_namespace
      ARGOCD_CHART_VERSION = var.argocd_chart_version
      GITOPS_REPO_URL      = var.togglemaster_gitops_repo_url
      GITOPS_BRANCH        = var.togglemaster_gitops_branch
      ADDONS_REPO_URL      = var.togglemaster_addons_repo_url
      ADDONS_BRANCH        = var.togglemaster_addons_branch
    }
  }
}
