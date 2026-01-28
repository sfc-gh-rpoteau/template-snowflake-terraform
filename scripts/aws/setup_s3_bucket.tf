########################################
# S3 bucket with Object Lock enabled
########################################

resource "aws_s3_bucket" "this" {
  bucket              = var.bucket_name
  object_lock_enabled = true

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Versioning (required for Object Lock)
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  object_lock_enabled = "Enabled" 

  depends_on = [aws_s3_bucket_versioning.this]
}

variable "bucket_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}