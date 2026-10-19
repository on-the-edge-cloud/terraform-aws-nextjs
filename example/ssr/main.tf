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

module "nextjs_ssr" {
  source = "../../modules/nextjs-ssr"

  environment     = "example"
  resource_prefix = "example-nextjs-"
  app_directory   = abspath("../..")
}