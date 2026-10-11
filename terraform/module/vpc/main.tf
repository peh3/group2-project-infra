data "aws_availability_zones" "available" {
  state = "available"
}

# Dedicated VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                     = "vpc-${var.cluster_name}-${var.environment}"
    Environment              = var.environment
    "karpenter.sh/discovery" = "${var.cluster_name}-${var.environment}"
  }
}

# 3 Public Subnets (For ALB Ingress)
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                                           = "${var.cluster_name}-public-${var.environment}-${data.aws_availability_zones.available.names[count.index]}"
    Environment                                                    = var.environment
    "kubernetes.io/role/elb"                                       = "1"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
  }
}

# 3 Private Subnets (For EKS Nodes & Application Microservices)
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                                           = "${var.cluster_name}-private-${var.environment}-${data.aws_availability_zones.available.names[count.index]}"
    Environment                                                    = var.environment
    "kubernetes.io/role/internal-elb"                              = "1"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
    "karpenter.sh/discovery"                                       = "${var.cluster_name}-${var.environment}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "igw-${var.cluster_name}-${var.environment}"
    Environment = var.environment
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "eip-nat-${var.cluster_name}-${var.environment}"
    Environment = var.environment
  }
}

# NAT Gateway (Single NAT per environment for cost discipline)
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "nat-${var.cluster_name}-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.this]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "rt-public-${var.cluster_name}-${var.environment}"
    Environment = var.environment
  }
}

# Private Route Table (Routes outbound traffic through NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name        = "rt-private-${var.cluster_name}-${var.environment}"
    Environment = var.environment
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}