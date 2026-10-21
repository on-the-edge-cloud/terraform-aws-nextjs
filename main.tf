terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

module "nextjs_ssr" {
  source = "./modules/nextjs-ssr"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  domain           = var.domain
  environment      = var.environment
  resource_prefix  = var.resource_prefix
  app_directory    = var.app_directory
  deploy_artifacts = var.deploy_artifacts
  force_destroy    = var.force_destroy
}