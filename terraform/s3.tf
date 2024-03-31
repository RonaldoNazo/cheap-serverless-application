resource "random_integer" "priority" {
  min = 1
  max = 50000
}
resource "aws_s3_bucket" "example" {
  bucket = "${var.s3_bucket_name}-${random_integer.priority.result}"
  tags = {
    Environment = "Test"
  }
}
resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = aws_s3_bucket.example.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = [var.domain_name]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "index.html"
  }

}
resource "aws_s3_bucket_policy" "allow_get_object" {
  bucket = aws_s3_bucket.example.id
  policy = data.aws_iam_policy_document.allow_get_object.json
}

data "aws_iam_policy_document" "allow_get_object" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.example.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}


resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.example.id
  key    = "index.html"
  source = "../s3website/index.html"
  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("../s3website/index.html")
  content_type = "text/html"
}