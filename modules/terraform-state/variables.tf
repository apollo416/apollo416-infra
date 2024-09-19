
variable "name_prefix" {
  description = "The prefix to apply to all resources"
  type        = string
}

variable "env" {
  description = "The environment to deploy to"
  type        = string
}

variable "kms_key_id" {
  description = "The ID of the KMS key"
  type        = string
}