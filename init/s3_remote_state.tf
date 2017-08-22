resource "aws_s3_bucket" "state" {
  bucket = "${var.project_name}-terraform-state"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true
    prefix  = "/"

    noncurrent_version_expiration {
      days = 30
    }
  }

  tags {
    Name = "${var.project_name} terraform bucket"
  }
}
