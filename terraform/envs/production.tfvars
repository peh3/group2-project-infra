environment        = "production"
cluster_name       = "swiftkart-eks-production"
vpc_cidr           = "10.20.0.0/16"
min_nodes          = 2
max_nodes          = 30
instance_types     = ["c6g.large", "c6g.xlarge"]
log_retention_days = 30