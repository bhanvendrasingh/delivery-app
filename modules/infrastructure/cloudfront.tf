# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "website" {
  count                             = var.enable_website ? 1 : 0
  name                              = "${var.project}-${var.environment}-website-oac"
  description                       = "Origin Access Control for ${var.project} ${var.environment} website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website" {
  count = var.enable_website ? 1 : 0

  # Origin 1 - S3 Static Website
  origin {
    domain_name              = aws_s3_bucket.website[0].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website[0].id
    origin_id                = "S3-${aws_s3_bucket.website[0].bucket}"
  }

  # Origin 2 - ALB Backend API (Go Bharat Microservices)
  origin {
    domain_name = var.website_config.alb_domain_name != null ? var.website_config.alb_domain_name : aws_lb.main.dns_name
    origin_id   = "ALB-${var.project}-${var.environment}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.enable_https ? "https-only" : "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout    = 30
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project} ${var.environment} website distribution (hybrid app + static content)"
  default_root_object = var.website_config.default_root_object
  web_acl_id          = var.environment == "prod" ? aws_wafv2_web_acl.main[0].arn : null

  # Custom domain configuration
  aliases = var.website_config.custom_domain != null ? [var.website_config.custom_domain] : []

  # Default Behavior - Static Website (S3)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website[0].bucket}"

    # Use managed cache policies for better performance and AWS best practices
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # CachingOptimized
    origin_request_policy_id   = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"  # CORS-S3Origin

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # API Behavior - Backend Services (ALB)
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${var.project}-${var.environment}"

    # Use managed cache policies for better performance and AWS best practices
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"  # CachingDisabled
    origin_request_policy_id   = "216adef6-5c7f-47e4-b989-5492eafa07d3"  # AllViewer

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }



  # Custom error pages
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  price_class = var.website_config.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL Certificate configuration
  viewer_certificate {
    acm_certificate_arn            = var.website_config.ssl_certificate_arn
    ssl_support_method             = var.website_config.ssl_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.website_config.ssl_certificate_arn != null ? "TLSv1" : null
    cloudfront_default_certificate = var.website_config.ssl_certificate_arn == null ? true : null
  }

  # HTTP version
  http_version = "http2"

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-website-distribution"
  })
}

