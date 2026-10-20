# Next.js SSR Module

Deploys an OpenNext build to Lambda, S3 and CloudFront, with DynamoDB and SQS-backed ISR revalidation.

```hcl
module "nextjs_ssr" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-ssr"
  version = "1.4.1"

  environment     = "pr-42"
  resource_prefix = "deploy-aws-pr-42-"
  app_directory   = abspath(".")
  force_destroy   = true
}
```

The module expects the OpenNext build at `app_directory/.open-next` and an AWS provider configured by the caller. It creates least-privilege Lambda roles, a private S3 bucket, CloudFront origins, a DynamoDB cache table, an SQS FIFO revalidation queue and a dead-letter queue. `deploy_artifacts = false` allows destroying resources without a local build.