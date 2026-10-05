# Local variables for the dev environment
variable "project_name" { type = string }
variable "environment" { type = string }
variable "owner" { type = string }
variable "region" { type = string }
variable "name_prefix" { type = string }
variable "tags" { type = map(string) }

# Calling VPC module variables

variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "availability_zones" { type = list(string) }

# Calling EKS module variables

variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "eks_version" { type = string }

# Calling IRSA module variables

variable "eks_oidc_provider_url" { type = string }
variable "eks_oidc_provider_arn" { type = string }
variable "route53_zone_arn" { type = string }

