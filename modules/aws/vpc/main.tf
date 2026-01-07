data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(var.availability_zones) > 0 ? slice(var.availability_zones, 0, var.azs_count) : slice(data.aws_availability_zones.available.names, 0, var.azs_count)
}

locals {
  public_subnet_cidrs  = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [for idx in range(var.azs_count) : cidrsubnet(var.vpc_cidr, 8, idx)]
  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [for idx in range(var.azs_count) : cidrsubnet(var.vpc_cidr, 8, idx + var.azs_count)]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    {
      Name        = "${var.vpc_name}-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_internet_gateway" "this" {
  count  = var.create_igw && var.create_public_subnets ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = merge(
    {
      Name        = "${var.vpc_name}-${var.environment}-igw"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_subnet" "public" {
  count = var.create_public_subnets ? var.azs_count : 0

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    {
      Name        = "${var.vpc_name}-${var.environment}-${var.public_subnet_suffix}-${local.azs[count.index]}"
      Environment = var.environment
      Type        = "public"
    },
    var.tags
  )
}

resource "aws_subnet" "private" {
  count = var.create_private_subnets ? var.azs_count : 0

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    {
      Name        = "${var.vpc_name}-${var.environment}-${var.private_subnet_suffix}-${local.azs[count.index]}"
      Environment = var.environment
      Type        = "private"
    },
    var.tags
  )
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.azs_count) : 0

  domain = "vpc"

  tags = merge(
    {
      Name        = "${var.vpc_name}-${var.environment}-nat-eip-${count.index + 1}"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.azs_count) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name        = "${var.vpc_name}-${var.environment}-nat-${local.azs[count.index]}"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  count = var.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = merge(
    {
      Name        = "${var.vpc_name}-${var.environment}-public-rt"
      Environment = var.environment
      Type        = "public"
    },
    var.tags
  )
}

resource "aws_route_table" "private" {
  count = var.create_private_subnets ? var.azs_count : 0

  vpc_id = aws_vpc.this.id
  tags = merge(
    {
      Name        = "${var.vpc_name}-${var.environment}-private-rt-${local.azs[count.index]}"
      Environment = var.environment
      Type        = "private"
    },
    var.tags
  )
}

resource "aws_route" "public_internet" {
  count                  = var.create_public_subnets && var.create_igw ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route" "private_nat" {
  count                  = var.create_private_subnets && var.enable_nat_gateway ? var.azs_count : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "public" {
  count = var.create_public_subnets ? var.azs_count : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = var.create_private_subnets ? var.azs_count : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  route_table_ids = concat(
    aws_route_table.public[*].id,
    aws_route_table.private[*].id
  )

  tags = merge(
    {
      Name        = "${var.vpc_name}-${var.environment}-s3-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  route_table_ids = concat(
    aws_route_table.public[*].id,
    aws_route_table.private[*].id
  )

  tags = merge(
    {
      Name        = "${var.vpc_name}-${var.environment}-dynamodb-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}


