terraform {
  required_version = ">= 1.10"

  # Configured via -backend-config in terraform init.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.69"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
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
  deployment_type = "ssr"
  pr_number       = "42"
}

output "preview_url" {
  value = module.nextjs.preview_url
}