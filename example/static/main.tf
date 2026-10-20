terraform {
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
}

output "preview_url" {
  value = module.nextjs.preview_url
}