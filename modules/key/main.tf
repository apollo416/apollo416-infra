
# Project KMS Key
resource "aws_kms_key" "main" {
  description             = "Project KMS Key"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 20
  tags = {
    Env = "prd"
  }
}

resource "aws_kms_key_policy" "main" {
  key_id = aws_kms_key.main.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"
        }
        Resource = ["*"]
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" : "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

