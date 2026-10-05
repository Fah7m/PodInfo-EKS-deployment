# Local variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

# IRSA Variables

variable "eks_oidc_provider_url" {
  description = "The URL of the EKS OIDC provider"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "The ARN of the EKS OIDC provider"
  type        = string
}

variable "route53_zone_arn" {
  description = "The ARN of the Route 53 hosted zone"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}