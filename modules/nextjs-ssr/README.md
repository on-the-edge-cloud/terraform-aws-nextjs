# Next.js SSR Module

Deploys an OpenNext build to Lambda, S3 and CloudFront, with DynamoDB and SQS-backed ISR revalidation.

```hcl
module "nextjs_ssr" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-ssr"
  version = "1.4.2"

  environment     = "pr-42"
  resource_prefix = "deploy-aws-pr-42-"
  app_directory   = abspath(".")
  force_destroy   = true
}
```

The module expects the OpenNext build at `app_directory/.open-next` and an AWS provider configured by the caller. It creates least-privilege Lambda roles, a private S3 bucket, CloudFront origins, a DynamoDB cache table, an SQS FIFO revalidation queue and a dead-letter queue. `deploy_artifacts = false` allows destroying resources without a local build.

## Custom domain

Add both inputs to the module call to serve a custom domain:

```hcl
domain              = "ontheedge.cloud"
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

The existing ACM certificate must be issued in **us-east-1** and cover `domain`. Omitting both inputs retains the default CloudFront domain and certificate. Certificate issuance and DNS records are managed outside this module. See the [custom domain setup](../../README.md#custom-domain-static-and-ssr) for ACM validation and Cloudflare configuration.