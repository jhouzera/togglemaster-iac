#!/usr/bin/env bash
set -euo pipefail

: "${AWS_REGION:?AWS_REGION nao definido}"
: "${CLUSTER_NAME:?CLUSTER_NAME nao definido}"
: "${ARGOCD_NAMESPACE:?ARGOCD_NAMESPACE nao definido}"
: "${ARGOCD_CHART_VERSION:?ARGOCD_CHART_VERSION nao definido}"
: "${GITOPS_REPO_URL:?GITOPS_REPO_URL nao definido}"
: "${GITOPS_BRANCH:?GITOPS_BRANCH nao definido}"

if ! command -v aws >/dev/null 2>&1; then
  echo "ERRO: aws cli nao encontrado"
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "ERRO: kubectl nao encontrado"
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "ERRO: helm nao encontrado"
  exit 1
fi

AWS_ARGS=()
KUBECONFIG_ARGS=(--region "${AWS_REGION}" --name "${CLUSTER_NAME}")
if [[ -n "${AWS_PROFILE:-}" ]]; then
  AWS_ARGS+=(--profile "${AWS_PROFILE}")
  KUBECONFIG_ARGS+=(--profile "${AWS_PROFILE}")
fi

if [[ -n "${EKS_ADMIN_ROLE_ARN:-}" ]]; then
  KUBECONFIG_ARGS+=(--role-arn "${EKS_ADMIN_ROLE_ARN}")
fi

aws "${AWS_ARGS[@]}" sts get-caller-identity
aws eks update-kubeconfig "${KUBECONFIG_ARGS[@]}"

kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update >/dev/null

helm upgrade --install argocd argo/argo-cd \
  --namespace "${ARGOCD_NAMESPACE}" \
  --version "${ARGOCD_CHART_VERSION}" \
  --set applicationSet.enabled=true \
  --set server.service.type=ClusterIP \
  --wait \
  --timeout 10m

kubectl rollout status deployment/argocd-server -n "${ARGOCD_NAMESPACE}" --timeout=10m
kubectl rollout status statefulset/argocd-application-controller -n "${ARGOCD_NAMESPACE}" --timeout=10m
kubectl rollout status deployment/argocd-applicationset-controller -n "${ARGOCD_NAMESPACE}" --timeout=10m || true

cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: togglemaster-apps
  namespace: ${ARGOCD_NAMESPACE}
spec:
  project: default
  source:
    repoURL: ${GITOPS_REPO_URL}
    targetRevision: ${GITOPS_BRANCH}
    path: bootstrap
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ARGOCD_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
EOF

kubectl delete application togglemaster-bootstrap \
  --namespace "${ARGOCD_NAMESPACE}" \
  --cascade=orphan \
  --ignore-not-found

kubectl delete application togglemaster-addons \
  --namespace "${ARGOCD_NAMESPACE}" \
  --ignore-not-found \
  --wait=true

kubectl delete applicationset togglemaster-addons \
  --namespace "${ARGOCD_NAMESPACE}" \
  --ignore-not-found \
  --wait=true

echo "ArgoCD instalado e Application togglemaster-apps aplicada com sucesso."
