# config networking resources for aws

# aws vpc 
resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name = "${local.name_prefix}-vpc"
  }
}

# internet gateway for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    name = "${local.name_prefix}-igw"
  }
}

# Create public subnets in different availability zones
resource "aws_subnet" "public_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_public_subnet_cidr[0]
  availability_zone = data.aws_availability_zones.availability.names[0]

  tags = {
    name = "${local.name_prefix}-public-subnet"
  }
}
resource "aws_subnet" "public_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_public_subnet_cidr[1]
  availability_zone = data.aws_availability_zones.availability.names[1]

  tags = {
    name = "${local.name_prefix}-public-subnet"
  }
}

# Create private subnets in different availability zones
resource "aws_subnet" "private_app_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_private_subnet_cidr[0]
  availability_zone = data.aws_availability_zones.availability.names[0]

  tags = {
    name = "${local.name_prefix}-private-subnet"
  }
}
resource "aws_subnet" "private_app_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_private_subnet_cidr[1]
  availability_zone = data.aws_availability_zones.availability.names[1]

  tags = {
    name = "${local.name_prefix}-private-subnet"
  }
}

# create nat gateway in public subnet for private subnet to access internet
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet1.id


  tags = {
    Name = "main-nat-gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# create route tables and associations
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    name = "${local.name_prefix}-public-rt"
  }
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    name = "${local.name_prefix}-private-rt"
  }
}
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_app_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_app_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}