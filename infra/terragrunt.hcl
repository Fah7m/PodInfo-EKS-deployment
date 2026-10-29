locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.env
}

remote_state {
  backend = "s3"

  config = {
    bucket         = "terraform-eks-state-${local.env}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    use_lockfile     = true
    
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "eu-west-2"
}

EOF
}
