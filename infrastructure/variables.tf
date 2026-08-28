variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name to use (leave empty to use default credential chain)"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name used as prefix for resources"
  type        = string
  default     = "togglemaster"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "AZs to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "use_nat_gateway" {
  description = "Create a single NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.30"
}

variable "node_instance_type" {
  description = "EKS node instance type"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 2
}

variable "lab_role_arn" {
  description = "ARN da LabRole a ser associada ao cluster EKS com permissao administrativa"
  type        = string
  default     = ""
}

variable "db_username" {
  description = "Master username for PostgreSQL instances"
  type        = string
  default     = "togglemaster"
}

variable "db_password" {
  description = "Master password for PostgreSQL instances"
  type        = string
  sensitive   = true
}

variable "service_api_key" {
  description = "API key interna usada pelo evaluation-service"
  type        = string
  default     = ""
  sensitive   = true
}

variable "master_key" {
  description = "Chave mestre usada pelo auth-service"
  type        = string
  default     = ""
  sensitive   = true
}

variable "keda_namespace" {
  description = "Namespace where KEDA runs"
  type        = string
  default     = "keda"
}

variable "keda_service_account_name" {
  description = "Kubernetes ServiceAccount used by KEDA for analytics scaler"
  type        = string
  default     = "keda-operator"
}

variable "nginx_namespace" {
  description = "Namespace where NGINX Gateway Fabric runs"
  type        = string
  default     = "nginx-gateway"
}

variable "nginx_service_account_name" {
  description = "ServiceAccount name for NGINX Gateway Fabric"
  type        = string
  default     = "nginx-gateway"
}

variable "metrics_namespace" {
  description = "Namespace where metrics-server runs"
  type        = string
  default     = "kube-system"
}

variable "metrics_service_account_name" {
  description = "ServiceAccount name for metrics-server"
  type        = string
  default     = "metrics-server"
}

variable "analytics_namespace" {
  description = "Namespace where analytics-service runs"
  type        = string
  default     = "analytics"
}

variable "analytics_service_account_name" {
  description = "ServiceAccount name for analytics-service"
  type        = string
  default     = "analytics-service-sa"
}

variable "evaluation_namespace" {
  description = "Namespace where evaluation-service runs"
  type        = string
  default     = "evaluation"
}

variable "evaluation_service_account_name" {
  description = "ServiceAccount name for evaluation-service"
  type        = string
  default     = "evaluation-service-sa"
}

variable "eso_namespace" {
  description = "Namespace do External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "eso_service_account_name" {
  description = "ServiceAccount do External Secrets Operator para IRSA"
  type        = string
  default     = "external-secrets"
}

variable "argocd_namespace" {
  description = "Namespace do ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Versao do chart oficial do ArgoCD"
  type        = string
  default     = "7.8.7"
}

variable "togglemaster_gitops_repo_url" {
  description = "URL do repositório GitOps com os charts e ApplicationSets"
  type        = string
  default     = "https://github.com/jhouzera/togglemaster-gitops.git"
}

variable "togglemaster_gitops_branch" {
  description = "Branch do repositorio GitOps"
  type        = string
  default     = "main"
}

variable "togglemaster_addons_repo_url" {
  description = "URL do repositório com os addons do cluster"
  type        = string
  default     = "https://github.com/jhouzera/togglemaster-addons.git"
}

variable "togglemaster_addons_branch" {
  description = "Branch do repositorio de addons"
  type        = string
  default     = "main"
}
