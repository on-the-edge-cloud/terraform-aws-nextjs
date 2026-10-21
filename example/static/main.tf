terraform {
  required_version = ">= 1.10"

  # Configured via -backend-config in terraform init.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.69"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "cloudflare" {}

module "nextjs" {
  source = "../../modules/nextjs-deployment"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  app_slug        = "example-nextjs"
  app_directory   = abspath("../..")
  deployment_type = "static"
  pr_number       = "42"
}

output "preview_url" {
  value = module.nextjs.preview_url
}