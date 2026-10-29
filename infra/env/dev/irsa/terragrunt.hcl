include "root" {
  path = find_in_parent_folders()
}

locals {
    env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
    secrets = read_terragrunt_config(find_in_parent_folders("secrets.hcl"))
}

terraform {
    source = "../../../modules/irsa"
}

dependency "eks" {
    config_path = "../eks"

    mock_outputs = {
    cluster_name = "my-eks-cluster"
    oidc_provider_url = "https://oidc.eks.eu-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
    }
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init", "refresh"]
}

inputs = {

    name_prefix = local.env.locals.name_prefix
    tags = local.env.locals.common_tags
    eks_oidc_provider_url = dependency.eks.outputs.oidc_provider_url
    eks_oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
    route53_zone_arn = local.secrets.locals.route53_zone_arn
    cluster_name = dependency.eks.outputs.cluster_name

}