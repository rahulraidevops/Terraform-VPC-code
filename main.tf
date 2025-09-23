# Fetch available AZs in the region
data "aws_availability_zones" "available" {}
/*data "aws_availability_zone" "available_zone" {
  state = "available"
}*/

resource "aws_vpc" "terra_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    Terraform   = "True"
  }
}

# Public Subnets
resource "aws_subnet" "web_subnet" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "data_subnet" {
  count                   = length(var.private_subnet_cidr)
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = var.private_subnet_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "terra_igw" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# Elastic IP for NAT
resource "aws_eip" "terra_nat_eip" {
  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

# NAT Gateway (in first public subnet)
resource "aws_nat_gateway" "terra_nat" {
  allocation_id = aws_eip.terra_nat_eip.id
  subnet_id     = aws_subnet.web_subnet[0].id
  depends_on    = [aws_internet_gateway.terra_igw]

  tags = {
    Name = "${var.environment}-nat-gw"
  }
}

# Public Route Table
resource "aws_route_table" "terra_public_rt" {
  vpc_id = aws_vpc.terra_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra_igw.id
  }

  tags = {
    Name = "${var.environment}-public-RT"
  }
}

# Private Route Table
resource "aws_route_table" "terra_private_rt" {
  vpc_id = aws_vpc.terra_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terra_nat.id
  }

  tags = {
    Name = "${var.environment}-private-RT"
  }
}

# Associations
resource "aws_route_table_association" "terra_public_assoc" {
  count          = length(aws_subnet.web_subnet)
  subnet_id      = aws_subnet.web_subnet[count.index].id
  route_table_id = aws_route_table.terra_public_rt.id
}

resource "aws_route_table_association" "terra_private_assoc" {
  count          = length(aws_subnet.data_subnet)
  subnet_id      = aws_subnet.data_subnet[count.index].id
  route_table_id = aws_route_table.terra_private_rt.id
}