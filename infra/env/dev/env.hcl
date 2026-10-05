locals {
    project_name = "eks"
    environment  = "dev"

    name_prefix = "${local.project_name}-${local.environment}"

    common_tags = {
        Project     = local.project_name
        Environment = local.environment
        }
}