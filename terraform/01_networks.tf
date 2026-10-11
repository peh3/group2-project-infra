# -------------------------------------------------------------
# 1. STAGING NETWORK
# -------------------------------------------------------------
module "vpc_staging" {
  source       = "./modules/vpc"
  environment  = "staging"
  vpc_cidr     = "10.10.0.0/16"
  cluster_name = "swiftkart-eks-staging"
}

# -------------------------------------------------------------
# 2. PRODUCTION NETWORK
# -------------------------------------------------------------
module "vpc_production" {
  source       = "./modules/vpc"
  environment  = "production"
  vpc_cidr     = "10.20.0.0/16"
  cluster_name = "swiftkart-eks-production"
}