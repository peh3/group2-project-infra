terraform {
  required_version = ">= 1.5.0"
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}