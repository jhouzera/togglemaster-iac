output "keda_irsa_role_arn" {
  value = aws_iam_role.keda_irsa.arn
}

output "nginx_irsa_role_arn" {
  value = aws_iam_role.nginx_irsa.arn
}

output "metrics_server_irsa_role_arn" {
  value = aws_iam_role.metrics_server_irsa.arn
}

output "analytics_irsa_role_arn" {
  value = aws_iam_role.analytics_irsa.arn
}

output "evaluation_irsa_role_arn" {
  value = aws_iam_role.evaluation_irsa.arn
}

output "eso_irsa_role_arn" {
  value = aws_iam_role.eso_irsa.arn
}

output "argocd_image_updater_irsa_role_arn" {
  description = "IAM Role ARN for ArgoCD Image Updater via IRSA"
  value       = aws_iam_role.argocd_image_updater_irsa.arn
}
