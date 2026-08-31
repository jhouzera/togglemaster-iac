variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "sqs_queue_arn" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}

variable "secrets_manager_arns" {
  type = list(string)
}

variable "keda_namespace" {
  type = string
}

variable "keda_service_account_name" {
  type = string
}

variable "nginx_namespace" {
  type = string
}

variable "nginx_service_account_name" {
  type = string
}

variable "metrics_namespace" {
  type = string
}

variable "metrics_service_account_name" {
  type = string
}

variable "analytics_namespace" {
  type = string
}

variable "analytics_service_account_name" {
  type = string
}

variable "evaluation_namespace" {
  type = string
}

variable "evaluation_service_account_name" {
  type = string
}

variable "eso_namespace" {
  type = string
}

variable "eso_service_account_name" {
  type = string
}

variable "ecr_repository_prefix" {
  type    = string
  default = "togglemaster-dev"
}
