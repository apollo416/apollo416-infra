
terraform {
  backend "s3" {
    bucket         = "unknown"
    key            = "unknown"
    region         = "us-east-1"
    dynamodb_table = "unknown"
  }
}
