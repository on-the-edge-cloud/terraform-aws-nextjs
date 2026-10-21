# Next.js Static Module

Deploys a Next.js static export from `app_directory/out` to a private S3 bucket served by CloudFront.

```hcl
module "nextjs_static" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-static"
  version = "1.4.2"

  environment     = "pr-42"
  resource_prefix = "deploy-aws-pr-42-"
  app_directory   = abspath(".")
  force_destroy   = true
}
```

The module expects the AWS provider to be configured by the caller. Set `deploy_artifacts = false` when destroying without a local build. Use `force_destroy = true` only for disposable preview buckets.

## Custom domain

Add both inputs to the module call to serve a custom domain:

```hcl
domain              = "ontheedge.cloud"
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

The existing ACM certificate must be issued in **us-east-1** and cover `domain`. Omitting both inputs retains the default CloudFront domain and certificate. Certificate issuance and DNS records are managed outside this module. See the [custom domain setup](../../README.md#custom-domain-static-and-ssr) for ACM validation and Cloudflare configuration.