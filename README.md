# terraform-aws-nextjs

Reusable Terraform modules for static and SSR Next.js deployments on AWS. The registry root module is SSR; static export is available as a submodule.

The examples below assume the caller configures the AWS provider in the application region, an AWS provider alias in `us-east-1`, and the Cloudflare provider. Cloudflare reads `CLOUDFLARE_API_TOKEN` from the environment.

```hcl
provider "aws" {
  region = "eu-north-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "cloudflare" {}
```

## SSR root module

```hcl
module "nextjs_ssr" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws"
  version = "1.4.2"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  environment      = "pr-42"
  resource_prefix  = "deploy-aws-pr-42-"
  app_directory    = abspath(".")
  force_destroy    = true
}
```

The SSR module deploys OpenNext Lambda bundles, private S3 assets/cache, CloudFront, DynamoDB and SQS-based ISR revalidation. The caller points `app_directory` to a checkout containing `.open-next/`.

## Static submodule

```hcl
module "nextjs_static" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws//modules/nextjs-static"
  version = "1.4.2"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  environment      = "pr-42"
  resource_prefix  = "deploy-aws-static-pr-42-"
  app_directory    = abspath(".")
  force_destroy    = true
}
```

The static module uploads `app_directory/out` to private S3 and serves it through CloudFront with OAC. Preview deployments should set `force_destroy = true`; production should leave it false. Use `deploy_artifacts = false` when destroying without a local build.

## Custom domain (static and SSR)

Pass only the domain:

```hcl
domain = "ontheedge.cloud"
```

Terraform requests an ACM certificate in **us-east-1**, creates its DNS validation records in Cloudflare, waits for issuance, and attaches it to CloudFront. Configure the AWS alias for `us-east-1` and set `CLOUDFLARE_API_TOKEN` with permission to list zones and edit DNS records. The domain may be a subdomain; Terraform selects the longest matching Cloudflare zone. The domain's zone must be accessible to that token.

CloudFront adds `domain` as an alternate domain name and uses the generated certificate with SNI and a TLS 1.2 minimum. Omitting `domain` keeps the default CloudFront domain and certificate. A custom domain can only be attached to one CloudFront distribution at a time, so use distinct domains for preview deployments.

The module creates ACM validation records as **DNS only**. After deployment, point the application's CNAME to the module's CloudFront hostname. Cloudflare proxying is optional; when proxied, use **Full (strict)** SSL/TLS. No S3 bucket or bucket policy changes are needed.

Wait for CloudFront deployment to complete. If a previously cached error persists, invalidate it:

```sh
aws cloudfront create-invalidation --distribution-id <distribution-id> --paths "/*"
```

## Simplified deployment module

Use [`modules/nextjs-deployment`](modules/nextjs-deployment/README.md) to select SSR or static deployment and derive preview naming from an application slug and pull request number. The caller still configures the AWS provider and Terraform backend.

Examples are in [`example/ssr`](example/ssr) and [`example/static`](example/static).
