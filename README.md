# terraform-aws-nextjs

Reusable Terraform modules for static and SSR Next.js deployments on AWS. The registry root module is SSR; static export is available as a submodule.

## SSR root module

```hcl
module "nextjs_ssr" {
  source  = "on-the-edge-cloud/terraform-aws-nextjs/aws"
  version = "1.4.1"

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
  version = "1.4.1"

  environment      = "pr-42"
  resource_prefix  = "deploy-aws-static-pr-42-"
  app_directory    = abspath(".")
  force_destroy    = true
}
```

The static module uploads `app_directory/out` to private S3 and serves it through CloudFront with OAC. Preview deployments should set `force_destroy = true`; production should leave it false. Use `deploy_artifacts = false` when destroying without a local build.

## Custom domain (static and SSR)

The root module and all deployment submodules accept these optional inputs together:

```hcl
domain              = "ontheedge.cloud"
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

Request and DNS-validate the ACM certificate in **us-east-1**, regardless of your application's AWS region. The certificate must be issued and cover the exact domain before applying. A wildcard such as `*.ontheedge.cloud` does not cover the apex `ontheedge.cloud`; include both names if needed. These modules attach an existing certificate; they do not create certificates or DNS records.

CloudFront adds `domain` as an alternate domain name and uses the ACM certificate with SNI and a TLS 1.2 minimum. Omitting both inputs keeps the default CloudFront domain and certificate. A custom domain can only be attached to one CloudFront distribution at a time, so use distinct domains for preview deployments.

In Cloudflare, add the ACM validation CNAME records as **DNS only**, using the names and values supplied by ACM. Point the application's CNAME to the module's CloudFront hostname. Cloudflare proxying is optional; when proxied, use **Full (strict)** SSL/TLS. Switching the application record to DNS only does not change the HTTP Host header: CloudFront still requires the custom domain alias and certificate. No S3 bucket or bucket policy changes are needed.

Wait for CloudFront deployment to complete. If a previously cached error persists, invalidate it:

```sh
aws cloudfront create-invalidation --distribution-id <distribution-id> --paths "/*"
```

## Simplified deployment module

Use [`modules/nextjs-deployment`](modules/nextjs-deployment/README.md) to select SSR or static deployment and derive preview naming from an application slug and pull request number. The caller still configures the AWS provider and Terraform backend.

Examples are in [`example/ssr`](example/ssr) and [`example/static`](example/static).
