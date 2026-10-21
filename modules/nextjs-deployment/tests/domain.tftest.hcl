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

mock_provider "archive" {}

mock_provider "cloudflare" {
  mock_data "cloudflare_zones" {
    defaults = {
      zones = [{ id = "zone-id", name = "ontheedge.cloud" }]
    }
  }
}

variables {
  app_slug         = "test-app"
  app_directory    = "."
  deployment_type  = "static"
  deploy_artifacts = false
}

run "preview_ignores_custom_domain" {
  command = plan

  variables {
    pr_number = "42"
    domain    = "preview.ontheedge.cloud"
  }

  assert {
    condition     = local.deployment_domain == null
    error_message = "Preview deployments must not receive the custom domain."
  }
}

run "production_uses_custom_domain" {
  command = plan

  variables {
    domain = "app.ontheedge.cloud"
  }

  assert {
    condition     = local.deployment_domain == var.domain
    error_message = "Production deployments must use the configured custom domain."
  }
}