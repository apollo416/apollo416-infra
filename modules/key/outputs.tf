
output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_key_id" {
  description = "The ID of the KMS key"
  value       = aws_kms_key.main.key_id
}
