terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket       = "terraform-eks-state-prod"
    key          = "eks-state"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true #S3 native locking
  }
}
