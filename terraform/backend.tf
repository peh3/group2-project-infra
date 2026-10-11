terraform {
  backend "s3" {
    bucket = "sctp-tfstate-ce13"
    key    = "group2/group2-project-infra.tfstate"
    region = "us-east-1"
  }
}