output "url" {
  value = module.nextjs_ssr.url
}

output "cloudfront_distribution_id" {
  value = module.nextjs_ssr.cloudfront_distribution_id
}

output "s3_bucket_name" {
  value = module.nextjs_ssr.s3_bucket_name
}