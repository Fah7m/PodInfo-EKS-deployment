# VPC Modue

module "vpc" {
  source      = "../../modules/vpc"
  name_prefix = "${var.project_name}-${var.environment}"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  region               = var.region


  tags = local.common_tags
}

# EKS Module

module "eks" {
  source      = "../../modules/eks"
  name_prefix = "${var.project_name}-${var.environment}"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  eks_version        = var.eks_version



  tags = local.common_tags
}

# CNI Module call

module "cni" {
  source      = "../../modules/irsa"
  name_prefix = "${var.project_name}-${var.environment}"

  eks_oidc_provider_url = module.eks.oidc_provider_url
  eks_oidc_provider_arn = module.eks.oidc_provider_arn

  tags = local.common_tags
}

# Cert Manager Module call

module "cert_manager" {
  source      = "../../modules/irsa"
  name_prefix = "${var.project_name}-${var.environment}"

  eks_oidc_provider_url = module.eks.oidc_provider_url
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  route53_zone_arn      = var.route53_zone_arn

  tags = local.common_tags
}

# External DNS Module call

module "external_dns" {
  source      = "../../modules/irsa"
  name_prefix = "${var.project_name}-${var.environment}"

  eks_oidc_provider_url = module.eks.oidc_provider_url
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  route53_zone_arn      = var.route53_zone_arn


  tags = local.common_tags
}