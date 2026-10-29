include "root" {
  path = find_in_parent_folders()
}

locals {
    env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
    secrets = read_terragrunt_config(find_in_parent_folders("secrets.hcl"))
}

terraform {
    source = "../../../modules/eks"
}


dependency "vpc" {
    config_path = "../vpc"

    mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
  }
  
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init", "refresh"]
}

inputs = {

    name_prefix = local.env.locals.name_prefix
    tags = local.env.locals.common_tags
    vpc_id = dependency.vpc.outputs.vpc_id
    private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
    eks_version = local.env.locals.eks_version
    cluster_admins = local.secrets.locals.cluster_admins

}