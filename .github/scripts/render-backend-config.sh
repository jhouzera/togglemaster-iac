#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="${1:-}"
ENV_NAME="${2:-}"

if [[ -z "${TARGET_FILE}" || -z "${ENV_NAME}" ]]; then
  echo "Uso: $0 <arquivo-backend.hcl> <ambiente>"
  exit 1
fi

: "${TF_BACKEND_BUCKET:?TF_BACKEND_BUCKET nao definido}"
: "${TF_BACKEND_REGION:?TF_BACKEND_REGION nao definido}"

cat > "${TARGET_FILE}" <<EOF
bucket       = "${TF_BACKEND_BUCKET}"
key          = "togglemaster/${ENV_NAME}/terraform.tfstate"
region       = "${TF_BACKEND_REGION}"
encrypt      = true
EOF

if [[ -n "${TF_BACKEND_ROLE_ARN:-}" ]]; then
  cat >> "${TARGET_FILE}" <<EOF
role_arn     = "${TF_BACKEND_ROLE_ARN}"
EOF
fi
