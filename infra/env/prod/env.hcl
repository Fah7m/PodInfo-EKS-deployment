locals {
    project_name = "eks"
    environment  = "prod"

    name_prefix = "${local.project_name}-${local.environment}"

    common_tags = {
        Project     = local.project_name
        Environment = local.environment
        }

    vpc_cidr = "10.0.0.0/16"
    public_subnet_cidrs = [
        "10.0.1.0/24",
        "10.0.2.0/24"
    ]
    private_subnet_cidrs = [
        "10.0.3.0/24",
        "10.0.4.0/24"
    ]
    availability_zones = ["eu-west-2a", "eu-west-2b"]
    region             = "eu-west-2"

    eks_version = "1.33"

    cni_addon_version = "v1.22.4-eksbuild.3"

    ebs_csi_driver_addon_version = "v1.66.0-eksbuild.1"

    ecr_repository_names = [
        "app",
    ]
}
