resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.4.4"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600

  values = [
    <<-EOT
    server:
      extraArgs:
        - --insecure
      additionalApplications:
        - name: bootstrap
          namespace: argocd
          project: default
          source:
            repoURL: ${var.gitops_repo_url}
            targetRevision: ${var.gitops_branch}
            path: bootstrap
          destination:
            server: https://kubernetes.default.svc
            namespace: argocd
          syncPolicy:
            automated:
              prune: true
              selfHeal: true
            syncOptions:
              - CreateNamespace=true
    EOT
  ]
}
