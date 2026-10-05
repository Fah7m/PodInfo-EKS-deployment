terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6"
    }

  }
}

provider "aws" {
  region = var.region


  default_tags {
    tags = local.common_tags
  }

}





