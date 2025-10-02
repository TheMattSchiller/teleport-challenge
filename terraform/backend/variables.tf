variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "teleport-challenge-terraform-state"
}

# Note: Lock table variable removed as we're using use_lockfile instead
