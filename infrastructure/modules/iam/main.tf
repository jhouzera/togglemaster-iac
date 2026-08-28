locals {
  name_prefix                         = "${var.project_name}-${var.environment}"
  oidc_provider_sub                   = "system:serviceaccount:${var.keda_namespace}:${var.keda_service_account_name}"
  oidc_provider_sub_nginx             = "system:serviceaccount:${var.nginx_namespace}:${var.nginx_service_account_name}"
  oidc_provider_sub_metrics           = "system:serviceaccount:${var.metrics_namespace}:${var.metrics_service_account_name}"
  oidc_provider_sub_analytics         = "system:serviceaccount:${var.analytics_namespace}:${var.analytics_service_account_name}"
  oidc_provider_sub_evaluation        = "system:serviceaccount:${var.evaluation_namespace}:${var.evaluation_service_account_name}"
  oidc_provider_sub_eso               = "system:serviceaccount:${var.eso_namespace}:${var.eso_service_account_name}"
  oidc_provider_sub_image_updater     = "system:serviceaccount:${var.argocd_image_updater_namespace}:${var.argocd_image_updater_service_account_name}"
  oidc_provider_issuer_without_scheme = replace(var.oidc_provider_url, "https://", "")
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  ecr_repository_arn = "arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_prefix}/*"
}

data "aws_region" "current" {}

resource "aws_iam_role" "keda_irsa" {
  name = "${local.name_prefix}-keda-sqs-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_issuer_without_scheme}:sub" = local.oidc_provider_sub
            "${local.oidc_provider_issuer_without_scheme}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "keda_sqs" {
  name        = "${local.name_prefix}-keda-sqs-policy"
  description = "Allow KEDA service account to read/delete SQS messages"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "keda_sqs" {
  role       = aws_iam_role.keda_irsa.name
  policy_arn = aws_iam_policy.keda_sqs.arn
}

# NGINX Gateway Fabric IRSA.
# Para o gateway "puro", o acesso AWS nao e estritamente obrigatorio.
# Ainda assim, criamos uma policy minima read-only para descoberta de rede/LB.
resource "aws_iam_role" "nginx_irsa" {
  name = "${local.name_prefix}-nginx-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_issuer_without_scheme}:sub" = local.oidc_provider_sub_nginx
            "${local.oidc_provider_issuer_without_scheme}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "nginx_discovery" {
  name        = "${local.name_prefix}-nginx-discovery-policy"
  description = "Read-only AWS permissions for NGINX Gateway Fabric service account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "nginx_discovery" {
  role       = aws_iam_role.nginx_irsa.name
  policy_arn = aws_iam_policy.nginx_discovery.arn
}

# metrics-server IRSA.
# metrics-server geralmente nao precisa chamar APIs da AWS diretamente,
# mas a role e criada para padronizacao e futuras extensoes.
resource "aws_iam_role" "metrics_server_irsa" {
  name = "${local.name_prefix}-metrics-server-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_issuer_without_scheme}:sub" = local.oidc_provider_sub_metrics
            "${local.oidc_provider_issuer_without_scheme}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# analytics-service IRSA: consume mensagens do SQS e gravar no DynamoDB.
resource "aws_iam_role" "analytics_irsa" {
  name = "${local.name_prefix}-analytics-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_issuer_without_scheme}:sub" = local.oidc_provider_sub_analytics
            "${local.oidc_provider_issuer_without_scheme}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "analytics_runtime" {
  name        = "${local.name_prefix}-analytics-runtime-policy"
  description = "Allow analytics-service to consume SQS and write to DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:UpdateItem"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "analytics_runtime" {
  role       = aws_iam_role.analytics_irsa.name
  policy_arn = aws_iam_policy.analytics_runtime.arn
}

# evaluation-service IRSA: publicar eventos na fila SQS.
resource "aws_iam_role" "evaluation_irsa" {
  name = "${local.name_prefix}-evaluation-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_issuer_without_scheme}:sub" = local.oidc_provider_sub_evaluation
            "${local.oidc_provider_issuer_without_scheme}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "evaluation_runtime" {
  name        = "${local.name_prefix}-evaluation-runtime-policy"
  description = "Allow evaluation-service to publish messages to SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:SendMessage"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "evaluation_runtime" {
  role       = aws_iam_role.evaluation_irsa.name
  policy_arn = aws_iam_policy.evaluation_runtime.arn
}

# External Secrets Operator IRSA: leitura de segredos no AWS Secrets Manager.
resource "aws_iam_role" "eso_irsa" {
  name = "${local.name_prefix}-eso-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_issuer_without_scheme}:sub" = local.oidc_provider_sub_eso
            "${local.oidc_provider_issuer_without_scheme}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eso_secretsmanager_read" {
  name        = "${local.name_prefix}-eso-secretsmanager-read"
  description = "Permite ao ESO ler segredos especificos no AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = var.secrets_manager_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso_secretsmanager_read" {
  role       = aws_iam_role.eso_irsa.name
  policy_arn = aws_iam_policy.eso_secretsmanager_read.arn
}

resource "aws_iam_role" "argocd_image_updater_irsa" {
  name = "${local.name_prefix}-argocd-image-updater-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_issuer_without_scheme}:sub" = local.oidc_provider_sub_image_updater
            "${local.oidc_provider_issuer_without_scheme}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "argocd_image_updater_ecr_read" {
  name        = "${local.name_prefix}-argocd-image-updater-ecr-read"
  description = "Permite ao ArgoCD Image Updater descobrir tags de imagens no ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages"
        ]
        Resource = local.ecr_repository_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argocd_image_updater_ecr_read" {
  role       = aws_iam_role.argocd_image_updater_irsa.name
  policy_arn = aws_iam_policy.argocd_image_updater_ecr_read.arn
}
