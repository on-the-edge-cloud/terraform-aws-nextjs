terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name  = trimsuffix(var.resource_prefix, "-")
  files = var.deploy_artifacts ? fileset("${var.app_directory}/out", "**") : toset([])
  matching_zones = var.domain == null ? [] : [
    for zone in data.cloudflare_zones.available[0].zones : zone
    if var.domain == zone.name || endswith(var.domain, ".${zone.name}")
  ]
  longest_zone_length = length(local.matching_zones) == 0 ? 0 : max([for zone in local.matching_zones : length(zone.name)]...)
  cloudflare_zone = try(one([
    for zone in local.matching_zones : zone
    if length(zone.name) == local.longest_zone_length
  ]), null)
  content_types = {
    css   = "text/css"
    html  = "text/html"
    ico   = "image/x-icon"
    jpeg  = "image/jpeg"
    jpg   = "image/jpeg"
    js    = "application/javascript"
    json  = "application/json"
    png   = "image/png"
    svg   = "image/svg+xml"
    txt   = "text/plain"
    webp  = "image/webp"
    woff  = "font/woff"
    woff2 = "font/woff2"
  }
}

resource "aws_s3_bucket" "site" {
  bucket        = "${local.name}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
  force_destroy = var.force_destroy
  tags          = { Environment = var.environment }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "site" {
  for_each = local.files

  bucket        = aws_s3_bucket.site.id
  key           = each.value
  source        = "${var.app_directory}/out/${each.value}"
  source_hash   = filemd5("${var.app_directory}/out/${each.value}")
  content_type  = lookup(local.content_types, element(split(".", each.value), length(split(".", each.value)) - 1), "application/octet-stream")
  cache_control = startswith(each.value, "_next/static/") ? "public,max-age=31536000,immutable" : "public,max-age=0,must-revalidate"
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${local.name}-assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  aliases             = var.domain == null ? [] : [var.domain]
  enabled             = true
  comment             = "Next.js static ${var.environment}"
  default_root_object = "index.html"
  is_ipv6_enabled     = true

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.domain == null
    acm_certificate_arn            = var.domain == null ? null : aws_acm_certificate_validation.domain[0].certificate_arn
    ssl_support_method             = var.domain == null ? null : "sni-only"
    minimum_protocol_version       = var.domain == null ? "TLSv1" : "TLSv1.2_2021"
  }

  tags = { Environment = var.environment }
}

resource "aws_acm_certificate" "domain" {
  count    = var.domain == null ? 0 : 1
  provider = aws.us_east_1

  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = local.cloudflare_zone != null
      error_message = "The domain must match a Cloudflare zone accessible to the configured API token."
    }
  }
}

resource "cloudflare_record" "acm_validation" {
  for_each = var.domain == null ? toset([]) : toset([var.domain])

  zone_id = local.cloudflare_zone.id
  name = one([
    for option in aws_acm_certificate.domain[0].domain_validation_options : option.resource_record_name
    if option.domain_name == each.key
  ])
  content = one([
    for option in aws_acm_certificate.domain[0].domain_validation_options : option.resource_record_value
    if option.domain_name == each.key
  ])
  type = one([
    for option in aws_acm_certificate.domain[0].domain_validation_options : option.resource_record_type
    if option.domain_name == each.key
  ])
  ttl     = 1
  proxied = false
}

resource "aws_acm_certificate_validation" "domain" {
  count    = var.domain == null ? 0 : 1
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.domain[0].arn
  validation_record_fqdns = [for record in cloudflare_record.acm_validation : record.hostname]
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontRead"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
        }
      }
    }]
  })
}