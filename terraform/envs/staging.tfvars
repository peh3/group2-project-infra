environment        = "staging"
cluster_name       = "swiftkart-eks-staging"
vpc_cidr           = "10.10.0.0/16"
min_nodes          = 1
max_nodes          = 3
instance_types     = ["t4g.medium"]
log_retention_days = 14