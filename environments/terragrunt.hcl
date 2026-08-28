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
  }
}
