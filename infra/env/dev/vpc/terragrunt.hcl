include "root" {
  path = find_in_parent_folders()
}

locals {
    env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
    source = "../../../modules/vpc"
}

inputs = {

    name_prefix = local.env.locals.name_prefix
    vpc_cidr = local.env.locals.vpc_cidr
    public_subnet_cidrs = local.env.locals.public_subnet_cidrs
    private_subnet_cidrs = local.env.locals.private_subnet_cidrs
    availability_zones = local.env.locals.availability_zones
    region = local.env.locals.region
    tags = local.env.locals.common_tags


}