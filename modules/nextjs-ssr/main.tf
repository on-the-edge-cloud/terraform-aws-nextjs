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

data "cloudflare_zones" "available" {
  count = var.domain == null ? 0 : 1

  filter {
    name        = "."
    lookup_type = "contains"
  }
}

locals {
  matching_zones = var.domain == null ? [] : [
    for zone in data.cloudflare_zones.available[0].zones : zone
    if var.domain == zone.name || endswith(var.domain, ".${zone.name}")
  ]
  longest_zone_length = length(local.matching_zones) == 0 ? 0 : max([for zone in local.matching_zones : length(zone.name)]...)
  cloudflare_zone = try(one([
    for zone in local.matching_zones : zone
    if length(zone.name) == local.longest_zone_length
  ]), null)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name       = var.name != "" ? var.name : trimsuffix(var.resource_prefix, "-")
  build_path = var.build_path != "" ? var.build_path : "${var.app_directory}/.open-next"
  functions = {
    server       = "server-functions/default"
    image        = "image-optimization-function"
    revalidation = "revalidation-function"
    initializer  = "dynamodb-provider"
  }
  cache_environment = {
    CACHE_BUCKET_NAME         = aws_s3_bucket.app.bucket
    CACHE_BUCKET_KEY_PREFIX   = "_cache"
    CACHE_BUCKET_REGION       = data.aws_region.current.region
    CACHE_DYNAMO_TABLE        = aws_dynamodb_table.cache.name
    REVALIDATION_QUEUE_URL    = aws_sqs_queue.revalidation.url
    REVALIDATION_QUEUE_REGION = data.aws_region.current.region
  }
}