include "root" {
  path = find_in_parent_folders()
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../modules/addons"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name = "my-eks-cluster"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init", "refresh"]
}

dependency "irsa" {
  config_path = "../irsa"

  mock_outputs = {
    cni_role_arn = "arn:aws:iam::123456789012:role/eks-cni-role"
    ebs_csi_driver_role_arn = "arn:aws:iam::123456789012:role/eks-ebs-csi-driver-role"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init", "refresh"]
}

inputs = {
  cluster_name      = dependency.eks.outputs.cluster_name
  cni_role_arn      = dependency.irsa.outputs.cni_role_arn
  cni_addon_version = local.env.locals.cni_addon_version
  ebs_csi_driver_addon_version = local.env.locals.ebs_csi_driver_addon_version
  ebs_csi_driver_role_arn = dependency.irsa.outputs.ebs_csi_driver_role_arn
  tags              = local.env.locals.common_tags
}