output "ebs_csi_driver_role_arn" {
  description = "The ARN of the IAM role created for EBS CSI Driver IRSA"
  value       = aws_iam_role.ebs_csi_driver_irsa.arn
}

output "cni_role_arn" {
  description = "The ARN of the IAM role created for CNI IRSA"
  value       = aws_iam_role.aws_node_irsa.arn
}

output "cert_manager_role_arn" {
  description = "The ARN of the IAM role created for Cert Manager IRSA"
  value       = aws_iam_role.cert_manager_irsa.arn
}

output "external_dns_role_arn" {
  description = "The ARN of the IAM role created for External DNS IRSA"
  value       = aws_iam_role.external_dns_irsa.arn
}

output "lbc_role_arn" {
  description = "The ARN of the IAM role created for Load Balancer Controller IRSA"
  value       = aws_iam_role.lbc_irsa.arn
}