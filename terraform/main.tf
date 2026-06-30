# 1. The Core S3 Bucket
resource "aws_s3_bucket" "this" {
  bucket        = "${local.name_prefix}-assets-bucket"
  force_destroy = true # Allows terraform destroy to clear files automatically in dev

  tags = local.common_tags
}

# 2. Bucket Versioning (Bonus/Requirement met)
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Public Access Block (Locking down the bucket completely)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. CloudFront Origin Access Control (OAC)
# This tells AWS that CloudFront is allowed to sign requests to access S3 securely.
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${local.name_prefix}-oac"
  description                       = "OAC for S3 Static Website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 5. CloudFront Distribution
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Origin Configuration: Linking CloudFront to our S3 bucket
  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.this.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # Default Cache Behavior (How CloudFront handles requests)
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.this.id}"
    viewer_protocol_policy = "redirect-to-https" # Enforce HTTPS

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Pricing tier and geo-restriction configuration
  price_class = "PriceClass_100" # Uses only US, Canada, and Europe (cheapest tier)

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL Certificate configuration (using default *.cloudfront.net cert)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}

# 6. S3 Bucket Policy
# This attaches the rule to S3 allowing ONLY our CloudFront distribution to read files.
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.this.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })
}