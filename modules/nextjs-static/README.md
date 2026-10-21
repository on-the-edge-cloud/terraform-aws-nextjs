# Next.js Static Module

Deploys a Next.js static export from `app_directory/out` to a private S3 bucket served by CloudFront.

```hcl
module "nextjs_static" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-static"
  version = "1.4.2"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  environment     = "pr-42"
  resource_prefix = "deploy-aws-pr-42-"
  app_directory   = abspath(".")
  force_destroy   = true
}
```

The caller configures AWS in the application region and in `us-east-1`, and configures Cloudflare. Set `CLOUDFLARE_API_TOKEN` in the environment. Set `deploy_artifacts = false` when destroying without a local build. Use `force_destroy = true` only for disposable preview buckets.

For custom domains, also pass `aws.us_east_1` and `cloudflare` provider configurations. Set `CLOUDFLARE_API_TOKEN` in the environment with permission to list zones and edit DNS records.

## Custom domain

Pass the domain to serve it:

```hcl
domain = "ontheedge.cloud"
```

Terraform requests and validates the ACM certificate in **us-east-1**, creates DNS validation records in the longest matching Cloudflare zone, and attaches the issued certificate to CloudFront. Omitting `domain` retains the default CloudFront domain and certificate. See the [custom domain setup](../../README.md#custom-domain-static-and-ssr) for provider configuration details.