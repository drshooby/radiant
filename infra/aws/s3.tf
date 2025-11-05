resource "aws_s3_bucket" "cloud_final_bucket" {
  bucket        = var.s3_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "cloud_final_bucket" {
  bucket = aws_s3_bucket.cloud_final_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "cloud_final_bucket" {
  bucket = aws_s3_bucket.cloud_final_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "cloud_final_bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.cloud_final_bucket,
    aws_s3_bucket_public_access_block.cloud_final_bucket,
  ]

  bucket = aws_s3_bucket.cloud_final_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "cloud_final_bucket" {
  bucket = aws_s3_bucket.cloud_final_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.cloud_final_bucket.id
  depends_on = [
    aws_s3_bucket_public_access_block.cloud_final_bucket
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.cloud_final_bucket.arn}/*"
      }
    ]
  })
}
