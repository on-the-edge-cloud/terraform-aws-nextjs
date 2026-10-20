# Next.js Static Module

Deploys a Next.js static export from `app_directory/out` to a private S3 bucket served by CloudFront.

```hcl
module "nextjs_static" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-static"
  version = "1.4.1"

  environment     = "pr-42"
  resource_prefix = "deploy-aws-pr-42-"
  app_directory   = abspath(".")
  force_destroy   = true
}
```

The module expects the AWS provider to be configured by the caller. Set `deploy_artifacts = false` when destroying without a local build. Use `force_destroy = true` only for disposable preview buckets.