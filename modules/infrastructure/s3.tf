# S3 Bucket for Website Hosting
resource "aws_s3_bucket" "website" {
  count  = var.enable_website ? 1 : 0
  bucket = "${var.project}-${var.environment}-website"

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-website"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "website" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Public Access Block (Secure - Block all public access)
resource "aws_s3_bucket_public_access_block" "website" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for Data Storage (File Uploads)
resource "aws_s3_bucket" "data" {
  count    = var.enable_data_bucket ? 1 : 0
  bucket   = "${var.project}-${var.environment}-data"
  provider = aws.us_east_1

  tags = merge(local.common_tags, {
    Name    = "${var.project}-${var.environment}-data"
    Purpose = "File uploads for Go Bharat Cab application"
  })
}

# S3 Bucket Versioning for Data Bucket
resource "aws_s3_bucket_versioning" "data" {
  count    = var.enable_data_bucket ? 1 : 0
  bucket   = aws_s3_bucket.data[0].id
  provider = aws.us_east_1
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Public Access Block (Allow public access for data bucket)
resource "aws_s3_bucket_public_access_block" "data" {
  count    = var.enable_data_bucket ? 1 : 0
  bucket   = aws_s3_bucket.data[0].id
  provider = aws.us_east_1

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket Lifecycle Configuration for Data Bucket
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  count    = var.enable_data_bucket ? 1 : 0
  bucket   = aws_s3_bucket.data[0].id
  provider = aws.us_east_1

  rule {
    id     = "data_lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.data]
}