# Minimal VPC: the account has no default VPC. Two public subnets (an ALB needs two AZs); instances get public IPs
# so they can pull the image without a NAT gateway.

locals {
  vpc_cidr = "10.10.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = local.name_prefix }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = local.name_prefix }
}

resource "aws_subnet" "public" {
  for_each = toset(local.azs)

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value
  cidr_block              = cidrsubnet(local.vpc_cidr, 8, index(local.azs, each.value))
  map_public_ip_on_launch = true

  tags = { Name = "${local.name_prefix}-public-${each.value}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${local.name_prefix}-public" }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
