#github-oidc-bootstrap
app_deployer_role_arn = "arn:aws:iam::255945442255:role/group2-project-app-deployer-role"
infra_deployer_role_arn = "arn:aws:iam::255945442255:role/group2-project-infra-deployer-role"


run below for testing eks in local:
aws eks update-kubeconfig --name capstone-group2-cluster --region ap-southeast-1

aws eks create-access-entry \
  --cluster-name capstone-group2-cluster \
  --principal-arn arn:aws:iam::255945442255:user/students/ce13/peh3 \
  --region ap-southeast-1

aws eks associate-access-policy \
  --cluster-name capstone-group2-cluster \
  --principal-arn arn:aws:iam::255945442255:user/students/ce13/peh3 \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region ap-southeast-1
