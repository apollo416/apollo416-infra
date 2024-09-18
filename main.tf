
locals {
  environments         = ["dev", "qa", "prd"]
  cost_allocation_tags = ["Env", "Rev"]
}

# cost_allocation_tag
resource "aws_ce_cost_allocation_tag" "main" {
  count   = length(local.cost_allocation_tags)
  tag_key = local.cost_allocation_tags[count.index]
  status  = "Active"
}

# aws_s3_bucket
resource "aws_s3_bucket" "main" {
  #checkov:skip=CKV_AWS_144:Ensure that S3 bucket has cross-region replication enabled
  #checkov:skip=CKV_AWS_18:Ensure the S3 bucket has access logging enabled
  #checkov:skip=CKV_AWS_145:Ensure that S3 buckets are encrypted with KMS by default
  for_each = toset(local.environments)
  bucket   = "apollo416-terraform-${each.value}"
  tags = {
    Env = "prd"
    Rev = "main"
  }
}

# aws_s3_bucket_versioning
resource "aws_s3_bucket_versioning" "main" {
  for_each = toset(local.environments)
  bucket   = aws_s3_bucket.main[each.value].id
  versioning_configuration {
    status = "Enabled"
  }
}

# aws_s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "main" {
  for_each                = toset(local.environments)
  bucket                  = aws_s3_bucket.main[each.value].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# aws_s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  for_each   = toset(local.environments)
  bucket     = aws_s3_bucket.main[each.value].id
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
  for_each = toset(local.environments)
  bucket   = aws_s3_bucket.main[each.value].id
  topic {
    topic_arn = aws_sns_topic.main[each.value].arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# aws_sns_topic
resource "aws_sns_topic" "main" {
  for_each          = toset(local.environments)
  name              = aws_s3_bucket.main[each.value].bucket
  kms_master_key_id = "alias/aws/sns"
  policy            = data.aws_iam_policy_document.main[each.value].json
  tags = {
    Env = "prd"
    Rev = "main"
  }
}

# aws_iam_policy_document
data "aws_iam_policy_document" "main" {
  for_each = toset(local.environments)
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:${aws_s3_bucket.main[each.value].bucket}"]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.main[each.value].arn]
    }
  }
}

resource "aws_dynamodb_table" "main" {
  #checkov:skip=CKV_AWS_119:Ensure DynamoDB Tables are encrypted using a KMS Customer Managed CMK
  #checkov:skip=CKV_AWS_28:Ensure DynamoDB point in time recovery (backup) is enabled
  for_each     = aws_s3_bucket.main
  name         = each.value.bucket
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Env = "prd"
    Rev = "main"
  }
}