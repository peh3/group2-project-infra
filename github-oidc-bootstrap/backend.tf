terraform {
  backend "s3" {
    key    = "tk/tk-tf-group2-infra-github-oidc-boostrap.tfstate"
    bucket = "sctp-core-tfstate"
    region = "ap-southeast-1"
  }
}