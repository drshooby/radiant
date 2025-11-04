output "spa_uri" {
  value = aws_s3_bucket_website_configuration.cloud_final_bucket.website_endpoint
}
