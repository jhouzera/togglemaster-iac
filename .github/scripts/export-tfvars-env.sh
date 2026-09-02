#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_ENV:?GITHUB_ENV nao definido}"

required_vars=(
  TF_VAR_db_password
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "ERRO: variavel obrigatoria ausente: ${var_name}"
    exit 1
  fi
  printf '%s=%s\n' "${var_name}" "${!var_name}" >> "${GITHUB_ENV}"
done

optional_vars=(
  TF_VAR_togglemaster_gitops_repo_url
  TF_VAR_togglemaster_gitops_branch
  TF_VAR_togglemaster_addons_repo_url
  TF_VAR_togglemaster_addons_branch
)

for var_name in "${optional_vars[@]}"; do
  if [[ -n "${!var_name:-}" ]]; then
    printf '%s=%s\n' "${var_name}" "${!var_name}" >> "${GITHUB_ENV}"
  fi
done
