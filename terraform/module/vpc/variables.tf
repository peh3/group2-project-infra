variable "environment" {
  description = "Environment name (e.g. staging, production)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster identifier for tagging"
  type        = string
  default     = "swiftkart-eks"
}