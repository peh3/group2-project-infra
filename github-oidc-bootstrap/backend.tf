terraform {
  backend "s3" {
    bucket = "sctp-tfstate-ce13"
    key    = "group2/group2-infra-github-iam-boostrap.tfstate"
    region = "us-east-1"
  }
}