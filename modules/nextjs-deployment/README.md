# Next.js Deployment Module

Deploys either an SSR or static Next.js application and derives resource names from an application slug and optional pull request number.

```hcl
module "nextjs" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-deployment"
  version = "1.4.1"

  app_slug        = "my-app"
  app_directory   = abspath(".")
  deployment_type = "ssr"
  pr_number       = "42"
}
```

Set `deployment_type` to `static` for a static export. Leave `pr_number` empty for production. Preview deployments automatically use a PR-specific environment and allow bucket destruction; production deployments do not. The caller still configures the AWS provider and Terraform backend.

Set `deploy_artifacts = false` when destroying without a local build. SSR builds must be available under `app_directory/.open-next`; static exports must be under `app_directory/out`.

Outputs include `url`, `preview_url`, `cloudfront_distribution_id` and `s3_bucket_name`.