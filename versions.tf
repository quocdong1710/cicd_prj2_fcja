# This file specifies the required Terraform version and the versions of the providers used in this configuration.
terraform {
  required_version = ">= 1.15.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0 , < 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.0 , < 4.0"
    }
  }
}