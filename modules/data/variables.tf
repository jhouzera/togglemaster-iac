variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "service_api_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "master_key" {
  type      = string
  default   = ""
  sensitive = true
}
