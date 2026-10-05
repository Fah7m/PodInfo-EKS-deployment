variable "cni_role_arn" {
  description = "The ARN of the IAM role for the CNI addon"
  type        = string
}

variable "cni_addon_version" {
  description = "The version of the CNI addon to use"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the addon"
  type        = map(string)
}

variable "ebs_csi_driver_addon_version" {
  description = "The version of the EBS CSI addon to use"
  type        = string
}

variable "ebs_csi_driver_role_arn" {
  description = "The ARN of the IAM role for the EBS CSI Driver addon"
  type        = string
}