# terraform-aws-nextjs

Reusable Terraform modules for static and SSR Next.js deployments on AWS. The registry root module is SSR; static export is available as a submodule.

## SSR root module

```hcl
module "nextjs_ssr" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws"
  version = "1.3.0"

  environment      = "pr-42"
  resource_prefix  = "deploy-aws-pr-42-"
  app_directory    = abspath(".")
  force_destroy    = true
}
```

The SSR module deploys OpenNext Lambda bundles, private S3 assets/cache, CloudFront, DynamoDB and SQS-based ISR revalidation. The caller configures the AWS provider and points `app_directory` to a checkout containing `.open-next/`.

## Static submodule

```hcl
module "nextjs_static" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-static"
  version = "1.3.0"

  environment      = "pr-42"
  resource_prefix  = "deploy-aws-static-pr-42-"
  app_directory    = abspath(".")
  force_destroy    = true
}
```

The static module uploads `app_directory/out` to private S3 and serves it through CloudFront with OAC. Preview deployments should set `force_destroy = true`; production should leave it false. Use `deploy_artifacts = false` when destroying without a local build.

Examples are in [`example/ssr`](example/ssr) and [`example/static`](example/static).
