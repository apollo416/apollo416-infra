
output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = module.key.kms_key_arn
}

output "kms_key_id" {
  description = "The ID of the KMS key"
  value       = module.key.kms_key_id
}
