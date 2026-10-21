# Next.js Deployment Module

Deploys either an SSR or static Next.js application and derives resource names from an application slug and optional pull request number.

```hcl
module "nextjs" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-deployment"
  version = "1.4.3"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  app_slug        = "my-app"
  app_directory   = abspath(".")
  deployment_type = "ssr"
  pr_number       = ""
  domain          = "app.ontheedge.cloud"
}
```

The caller configures AWS providers for the application region and `us-east-1`, plus Cloudflare with `CLOUDFLARE_API_TOKEN`. Terraform creates and validates the ACM certificate and validation records automatically. A custom domain is applied only when `pr_number` is empty; previews always use their default CloudFront hostname, even if `domain` is set. Omit `domain` to use only the default CloudFront domain in production too.

Set `deployment_type` to `static` for a static export. Leave `pr_number` empty for production. Preview deployments automatically use a PR-specific environment and allow bucket destruction; production deployments do not. The caller still configures the AWS provider and Terraform backend.

Set `deploy_artifacts = false` when destroying without a local build. SSR builds must be available under `app_directory/.open-next`; static exports must be under `app_directory/out`.

Outputs include `url`, `preview_url`, `cloudfront_distribution_id` and `s3_bucket_name`.

## Custom domain

Both `deployment_type = "static"` and `deployment_type = "ssr"` support this optional input:

```hcl
domain = "ontheedge.cloud"
```

Terraform creates the production ACM certificate in **us-east-1** and validates it through DNS records in Cloudflare. Preview deployments do not receive or claim the production domain. See the [custom domain setup](../../README.md#custom-domain-static-and-ssr) for provider configuration details.