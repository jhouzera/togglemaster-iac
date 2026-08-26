locals {
  name_prefix = "${var.project_name}-${var.environment}"
  repositories = [
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service"
  ]
}

resource "aws_ecr_repository" "this" {
  for_each = toset(local.repositories)

  name                 = "${local.name_prefix}/${each.value}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
