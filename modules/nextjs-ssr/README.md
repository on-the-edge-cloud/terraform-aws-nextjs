# Next.js SSR Module

Deploys an OpenNext build to Lambda, S3 and CloudFront, with DynamoDB and SQS-backed ISR revalidation.

```hcl
module "nextjs_ssr" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-ssr"
  version = "1.4.3"

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

The module expects the OpenNext build at `app_directory/.open-next`. The caller configures AWS in the application region and in `us-east-1`, and configures Cloudflare. Set `CLOUDFLARE_API_TOKEN` in the environment. It creates least-privilege Lambda roles, a private S3 bucket, CloudFront origins, a DynamoDB cache table, an SQS FIFO revalidation queue and a dead-letter queue. `deploy_artifacts = false` allows destroying resources without a local build.

For custom domains, also pass `aws.us_east_1` and `cloudflare` provider configurations. Set `CLOUDFLARE_API_TOKEN` in the environment with permission to list zones and edit DNS records.

## Custom domain

Pass the domain to serve it:

```hcl
domain = "ontheedge.cloud"
```

Terraform requests and validates the ACM certificate in **us-east-1**, creates DNS validation records in the longest matching Cloudflare zone, and attaches the issued certificate to CloudFront. Omitting `domain` retains the default CloudFront domain and certificate. See the [custom domain setup](../../README.md#custom-domain-static-and-ssr) for provider configuration details.