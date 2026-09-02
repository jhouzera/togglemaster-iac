include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../infrastructure///"
}

inputs = {
  aws_region   = "us-east-1"
  project_name = "togglemaster"
  environment  = "dev"
  aws_profile  = ""

  use_nat_gateway = true

  eks_cluster_version = "1.36"
  eks_endpoint_public_access  = true
  eks_endpoint_private_access = true
  eks_public_access_cidrs     = ["0.0.0.0/0"]
  node_instance_type  = "t3.medium"
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 5
  lab_role_arn        = ""

  keda_namespace            = "keda"
  keda_service_account_name = "keda-operator"

  nginx_namespace            = "nginx-gateway"
  nginx_service_account_name = "nginx-gateway"

  metrics_namespace            = "kube-system"
  metrics_service_account_name = "metrics-server"

  analytics_namespace            = "analytics"
  analytics_service_account_name = "analytics-service-sa"

  evaluation_namespace            = "evaluation"
  evaluation_service_account_name = "evaluation-service-sa"

  eso_namespace            = "external-secrets"
  eso_service_account_name = "external-secrets"
}
