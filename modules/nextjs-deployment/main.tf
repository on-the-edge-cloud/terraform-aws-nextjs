terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
    archive = {
      source = "hashicorp/archive"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

locals {
  is_preview        = var.pr_number != ""
  deployment_domain = local.is_preview ? null : var.domain
  environment       = local.is_preview ? "pr-${var.pr_number}" : "production"
  resource_stem     = var.deployment_type == "static" ? "${var.app_slug}-static" : var.app_slug
  resource_prefix   = local.is_preview ? "${local.resource_stem}-pr-${var.pr_number}-" : "${local.resource_stem}-prod-"
  resource_name     = trimsuffix(local.resource_prefix, "-")
}

module "ssr" {
  source = "../nextjs-ssr"
  count  = var.deployment_type == "ssr" ? 1 : 0

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  domain           = local.deployment_domain
  name             = local.resource_name
  environment      = local.environment
  resource_prefix  = local.resource_prefix
  app_directory    = var.app_directory
  deploy_artifacts = var.deploy_artifacts
  force_destroy    = local.is_preview
}

module "static" {
  source = "../nextjs-static"
  count  = var.deployment_type == "static" ? 1 : 0

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  domain           = local.deployment_domain
  environment      = local.environment
  resource_prefix  = local.resource_prefix
  app_directory    = var.app_directory
  deploy_artifacts = var.deploy_artifacts
  force_destroy    = local.is_preview
}