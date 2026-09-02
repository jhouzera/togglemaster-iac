variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "gitops_repo_url" {
  description = "URL do repositorio GitOps (ex: https://github.com/jhouzera/togglemaster-gitops.git)"
  type        = string
  default     = "https://github.com/jhouzera/togglemaster-gitops.git"
}

variable "gitops_branch" {
  description = "Branch do repositorio GitOps"
  type        = string
  default     = "main"
}
