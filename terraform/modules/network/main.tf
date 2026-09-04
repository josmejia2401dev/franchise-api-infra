locals {
  name = "${var.project}-${var.environment}"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.name}-vpc"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${local.name}-igw"
    Project     = var.project
    Environment = var.environment
  }
}

# Public subnets host the ALB and the NAT gateway.
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name}-public-${count.index}"
    Project     = var.project
    Environment = var.environment
    Tier        = "public"
  }
}

# Private subnets host the ECS Fargate tasks.
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${local.name}-private-${count.index}"
    Project     = var.project
    Environment = var.environment
    Tier        = "private"
  }
}

# Single EIP + NAT gateway to give the private subnets outbound internet
# access (needed to reach MongoDB Atlas and pull nothing else at runtime).
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${local.name}-nat-eip"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${local.name}-nat"
    Project     = var.project
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.this]
}

# Public route table: traffic to the internet goes through the IGW.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "${local.name}-public-rt"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route table: outbound traffic goes through the NAT gateway.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name        = "${local.name}-private-rt"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
