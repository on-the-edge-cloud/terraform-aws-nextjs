mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }

  mock_data "aws_region" {
    defaults = { region = "eu-north-1" }
  }
}

mock_provider "archive" {}

variables {
  environment      = "test"
  resource_prefix  = "domain-test-"
  app_directory    = "."
  deploy_artifacts = false
}

run "default_domain" {
  command = plan

  assert {
    condition     = length(aws_cloudfront_distribution.app.aliases) == 0 && aws_cloudfront_distribution.app.viewer_certificate[0].cloudfront_default_certificate
    error_message = "Without custom inputs, CloudFront must keep its default domain and certificate."
  }
}

run "custom_domain" {
  command = plan

  variables {
    domain              = "ontheedge.cloud"
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = aws_cloudfront_distribution.app.aliases == toset([var.domain])
    error_message = "CloudFront must register the custom domain as an alias."
  }

  assert {
    condition = (
      !aws_cloudfront_distribution.app.viewer_certificate[0].cloudfront_default_certificate &&
      aws_cloudfront_distribution.app.viewer_certificate[0].acm_certificate_arn == var.acm_certificate_arn &&
      aws_cloudfront_distribution.app.viewer_certificate[0].ssl_support_method == "sni-only" &&
      aws_cloudfront_distribution.app.viewer_certificate[0].minimum_protocol_version == "TLSv1.2_2021"
    )
    error_message = "Custom domains must use the provided ACM certificate with SNI and TLS 1.2."
  }
}

run "domain_requires_certificate" {
  command = plan

  variables {
    domain = "ontheedge.cloud"
  }

  expect_failures = [aws_cloudfront_distribution.app]
}

run "certificate_requires_domain" {
  command = plan

  variables {
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  expect_failures = [aws_cloudfront_distribution.app]
}

run "certificate_requires_us_east_1" {
  command = plan

  variables {
    domain              = "ontheedge.cloud"
    acm_certificate_arn = "arn:aws:acm:eu-north-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  expect_failures = [var.acm_certificate_arn]
}