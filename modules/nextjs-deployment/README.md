# Next.js Deployment Module

Deploys either an SSR or static Next.js application and derives resource names from an application slug and optional pull request number.

```hcl
module "nextjs" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-deployment"
  version = "1.4.2"

  app_slug        = "my-app"
  app_directory   = abspath(".")
  deployment_type = "ssr"
  pr_number       = "42"

  domain              = "ssr-pr-42.ontheedge.cloud"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}
```

Replace the example domain and certificate ARN with your own values. The certificate must be issued in **us-east-1** and cover the domain. Omit both inputs to use only the default CloudFront domain. The [static example](../../example/static/main.tf) and [SSR example](../../example/ssr/main.tf) use distinct preview subdomains; point the chosen domain's DNS record to the resulting CloudFront hostname.

Set `deployment_type` to `static` for a static export. Leave `pr_number` empty for production. Preview deployments automatically use a PR-specific environment and allow bucket destruction; production deployments do not. The caller still configures the AWS provider and Terraform backend.

Set `deploy_artifacts = false` when destroying without a local build. SSR builds must be available under `app_directory/.open-next`; static exports must be under `app_directory/out`.

Outputs include `url`, `preview_url`, `cloudfront_distribution_id` and `s3_bucket_name`.

## Custom domain

Both `deployment_type = "static"` and `deployment_type = "ssr"` support these optional inputs:

```hcl
domain              = "ontheedge.cloud"
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

Set both inputs or omit both to retain the default CloudFront domain and certificate. The existing ACM certificate must be issued in **us-east-1** and cover `domain`. Use a distinct domain for each preview distribution. Certificate issuance and DNS records are managed outside this module. See the [custom domain setup](../../README.md#custom-domain-static-and-ssr) for ACM validation and Cloudflare configuration.