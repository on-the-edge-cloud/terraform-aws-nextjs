mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }

  mock_data "aws_region" {
    defaults = { region = "eu-north-1" }
  }
}

mock_provider "aws" {
  alias = "us_east_1"
}

mock_provider "cloudflare" {
  mock_data "cloudflare_zones" {
    defaults = {
      zones = [{ id = "zone-id", name = "ontheedge.cloud" }]
    }
  }
}

variables {
  environment      = "test"
  resource_prefix  = "domain-test-"
  app_directory    = "."
  deploy_artifacts = false
}

run "default_domain" {
  command = plan

  assert {
    condition     = length(aws_cloudfront_distribution.site.aliases) == 0 && aws_cloudfront_distribution.site.viewer_certificate[0].cloudfront_default_certificate
    error_message = "Without custom inputs, CloudFront must keep its default domain and certificate."
  }
}

run "custom_domain" {
  command = plan

  variables {
    domain = "ontheedge.cloud"
  }

  assert {
    condition     = aws_cloudfront_distribution.site.aliases == toset([var.domain])
    error_message = "CloudFront must register the custom domain as an alias."
  }

  assert {
    condition = (
      !aws_cloudfront_distribution.site.viewer_certificate[0].cloudfront_default_certificate &&
      aws_cloudfront_distribution.site.viewer_certificate[0].ssl_support_method == "sni-only" &&
      aws_cloudfront_distribution.site.viewer_certificate[0].minimum_protocol_version == "TLSv1.2_2021"
    )
    error_message = "Custom domains must use an ACM certificate with SNI and TLS 1.2."
  }

  assert {
    condition = (
      aws_acm_certificate.domain[0].domain_name == var.domain &&
      aws_acm_certificate.domain[0].validation_method == "DNS" &&
      cloudflare_record.acm_validation[var.domain].zone_id == "zone-id"
    )
    error_message = "A custom domain must create an ACM certificate and Cloudflare validation record automatically."
  }
}