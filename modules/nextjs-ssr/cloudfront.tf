resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${local.name}-assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "forward_host" {
  name    = "${local.name}-forward-host"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-JS
    function handler(event) {
      var request = event.request;
      request.headers["x-forwarded-host"] = request.headers.host;
      return request;
    }
  JS
}

data "aws_cloudfront_cache_policy" "static" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "server" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_cache_policy" "server" {
  name        = "${local.name}-server"
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "all"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["accept", "rsc", "next-router-prefetch", "next-router-state-tree", "next-url", "x-prerender-revalidate"]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_distribution" "app" {
  aliases         = var.domain == null ? [] : [var.domain]
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Next.js ${var.environment}"
  price_class     = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.app.bucket_regional_domain_name
    origin_id                = "assets"
    origin_path              = "/_assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }

  dynamic "origin" {
    for_each = aws_lambda_function_url.app

    content {
      domain_name = trimsuffix(trimprefix(origin.value.function_url, "https://"), "/")
      origin_id   = origin.key

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
        origin_read_timeout    = 30
      }
    }
  }

  default_cache_behavior {
    target_origin_id         = "server"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
    cache_policy_id          = aws_cloudfront_cache_policy.server.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.server.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.forward_host.arn
    }
  }

  ordered_cache_behavior {
    path_pattern             = "/_next/image*"
    target_origin_id         = "image"
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
    cache_policy_id          = aws_cloudfront_cache_policy.server.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.server.id
  }

  ordered_cache_behavior {
    path_pattern           = "/_next/static/*"
    target_origin_id       = "assets"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.static.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.domain == null
    acm_certificate_arn            = var.domain == null ? null : aws_acm_certificate_validation.domain[0].certificate_arn
    ssl_support_method             = var.domain == null ? null : "sni-only"
    minimum_protocol_version       = var.domain == null ? "TLSv1" : "TLSv1.2_2021"
  }

  tags = { Environment = var.environment }

  depends_on = [aws_lambda_permission.url, aws_lambda_permission.invoke, aws_s3_object.assets, aws_lambda_invocation.initialize_cache]
}

resource "aws_acm_certificate" "domain" {
  count    = var.domain == null ? 0 : 1
  provider = aws.us_east_1

  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = local.cloudflare_zone != null
      error_message = "The domain must match a Cloudflare zone accessible to the configured API token."
    }
  }
}

resource "cloudflare_record" "acm_validation" {
  for_each = var.domain == null ? toset([]) : toset([var.domain])

  zone_id = local.cloudflare_zone.id
  name = one([
    for option in aws_acm_certificate.domain[0].domain_validation_options : option.resource_record_name
    if option.domain_name == each.key
  ])
  content = one([
    for option in aws_acm_certificate.domain[0].domain_validation_options : option.resource_record_value
    if option.domain_name == each.key
  ])
  type = one([
    for option in aws_acm_certificate.domain[0].domain_validation_options : option.resource_record_type
    if option.domain_name == each.key
  ])
  ttl     = 1
  proxied = false
}

resource "aws_acm_certificate_validation" "domain" {
  count    = var.domain == null ? 0 : 1
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.domain[0].arn
  validation_record_fqdns = [for record in cloudflare_record.acm_validation : record.hostname]
}