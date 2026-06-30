output "s3_bucket_name" {
  value       = aws_s3_bucket.this.id
  description = "The name of the S3 bucket"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "The domain name of the CloudFront distribution"
}
