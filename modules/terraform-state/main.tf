
locals {
  name = "${var.name_prefix}-${var.env}"
}

# aws_s3_bucket
resource "aws_s3_bucket" "main" {
  bucket = local.name
  tags = {
    Env = "prd"
    Rev = "main"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

# aws_s3_bucket_versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

# aws_s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# aws_s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket     = aws_s3_bucket.main.bucket
  depends_on = [aws_s3_bucket_versioning.main]
  rule {
    id     = "rule-1"
    status = "Enabled"
    expiration {
      days = 10
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 10
    }
  }
}

# aws_s3_bucket_notification
resource "aws_s3_bucket_notification" "main" {
  bucket = aws_s3_bucket.main.id
  topic {
    topic_arn = aws_sns_topic.main.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# aws_sns_topic
resource "aws_sns_topic" "main" {
  name              = aws_s3_bucket.main.bucket
  kms_master_key_id = var.kms_key_id
  policy            = data.aws_iam_policy_document.main.json
  tags = {
    Env = "prd"
    Rev = "main"
  }
}

# aws_iam_policy_document
data "aws_iam_policy_document" "main" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:${aws_s3_bucket.main.bucket}"]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.main.arn]
    }
  }
}

resource "aws_dynamodb_table" "main" {
  name         = aws_s3_bucket.main.bucket
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }
  point_in_time_recovery {
    enabled = true
  }
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Env = "prd"
    Rev = "main"
  }
}