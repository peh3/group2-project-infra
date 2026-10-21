variable "aws_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "AWS region for all resources"
}
variable "prefix" {
  type        = string
  default     = "tk-tf"
  description = "Prefix for all resources"
}
variable "name" {
  type        = string
  default     = "tk-tf"
  description = "Name for all resources"
}

# ==========================================================
# Variables & Outputs
# ==========================================================
variable "github_repository_username" {
  description = "GitHub repository username"
  type        = string
  default     = "peh3"
}

variable "github_app_repository_name" {
  description = "GitHub repository name for application"
  type        = string
  default     = "group2-project-app"
}

variable "github_infra_repository_name" {
  description = "GitHub repository name for Terraform infra"
  type        = string
  default     = "group2-project-infra"
}

variable "tfstate_bucket_name" {
  description = "S3 bucket storing terraform state"
  type        = string
  default     = "sctp-core-tfstate"
}
