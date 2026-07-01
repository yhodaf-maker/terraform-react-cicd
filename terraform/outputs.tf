output "bucket_name" {
  description = "S3 bucket name"

  value = aws_s3_bucket.website.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"

  value = aws_s3_bucket.website.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"

  value = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront URL"

  value = aws_cloudfront_distribution.website.domain_name
}