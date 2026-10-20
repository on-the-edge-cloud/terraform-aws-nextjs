output "url" {
  value = var.deployment_type == "ssr" ? module.ssr[0].url : module.static[0].url
}

output "preview_url" {
  value = var.deployment_type == "ssr" ? module.ssr[0].url : module.static[0].preview_url
}

output "cloudfront_distribution_id" {
  value = var.deployment_type == "ssr" ? module.ssr[0].cloudfront_distribution_id : module.static[0].cloudfront_distribution_id
}

output "s3_bucket_name" {
  value = var.deployment_type == "ssr" ? module.ssr[0].s3_bucket_name : module.static[0].s3_bucket_name
}