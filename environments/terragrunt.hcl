remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = get_env("TF_BACKEND_BUCKET", "")
    key          = "togglemaster/${path_relative_to_include()}/terraform.tfstate"
    region       = get_env("TF_BACKEND_REGION", "")
    encrypt      = true
    use_lockfile = true

    # Evita que o Terragrunt tente alterar as policies/encryption do bucket de estado
    skip_bucket_ssencryption = true
    skip_bucket_root_access  = true
    skip_bucket_enforced_tls = true
    disable_bucket_update    = true
  }
}
