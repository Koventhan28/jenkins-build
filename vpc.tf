


############################
# VPC + Networking (us-west-1)
############################
resource "aws_vpc" "main_vpc" {
  provider             = aws.west
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Main_VPC"
  }
}

resource "aws_internet_gateway" "internet" {
  provider = aws.west
  vpc_id   = aws_vpc.main_vpc.id
}

############################
# Public Subnet
############################
resource "aws_subnet" "public" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.main_vpc.id
  #  automatically assigns a public IPv4 address to any network interface (ENI) launched into that subnet the below line
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index) # Calculates: 10.0.0.0/24, 10.0.1.0/24...
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "public-${count.index}-${data.aws_availability_zones.available.names[count.index]}"
  }
}
############################
# Private Subnet
############################
resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index + length(data.aws_availability_zones.available.names)) # Calculates: 10.0.0.0/24, 10.0.1.0/24...
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "public-${count.index}-${data.aws_availability_zones.available.names[count.index]}"
  }
}
############################
# Public Route
############################
resource "aws_route_table" "public_route" {
  provider = aws.west
  vpc_id   = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet.id
  }
}
############################
# Private Route
############################
resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main_vpc.id
  # Only Local routing enabled 
  tags = {
    Name = "private-route"
  }
}
############################
# Public Route Table
############################
resource "aws_route_table_association" "public_route_table" {
  provider = aws.west
  count    = length(data.aws_availability_zones.available.names)
  # The output of the public route will be a tulip
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public_route.id
}
############################
# Private Route Table
############################
resource "aws_route_table_association" "private_route_table" {
  provider = aws.west
  count    = length(data.aws_availability_zones.available.names)
  # The output of the private route will be a tulip converting to using element for loop
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private_route.id
}


output "availability" {
  value = data.aws_availability_zones.available
}
