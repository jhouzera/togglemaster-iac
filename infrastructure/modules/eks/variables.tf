variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "node_instance_type" {
  type = string
}

variable "node_desired_size" {
  type = number
}

variable "node_min_size" {
  type = number
}

variable "cluster_admin_arns" {
  description = "List of IAM ARNs that should be granted Cluster Admin access via EKS Access Entries (e.g., GitHub Actions role)"
  type        = list(string)
  default     = []
}

variable "node_max_size" {
  type = number
}

variable "eks_admin_trusted_principal_arns" {
  description = "IAM user or role ARNs allowed to assume the dedicated EKS administrator role"
  type        = list(string)
  default     = []
}
