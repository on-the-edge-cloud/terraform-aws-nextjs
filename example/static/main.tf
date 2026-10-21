terraform {
  required_version = ">= 1.10"

  # Configured via -backend-config in terraform init.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.69"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

module "nextjs" {
  source = "../../modules/nextjs-deployment"

  app_slug        = "example-nextjs"
  app_directory   = abspath("../..")
  deployment_type = "static"
  pr_number       = "42"

  domain              = "static-pr-42.ontheedge.cloud"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}

output "preview_url" {
  value = module.nextjs.preview_url
}