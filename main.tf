resource "aws_vpc" "mod" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name        = var.name
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.mod.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.name}.public.${element(var.availability_zones, count.index)}"
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.mod.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)
  count             = length(var.private_subnets)

  tags = {
    Name        = "${var.name}.private.${element(var.availability_zones, count.index)}"
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "mod" {
  vpc_id = aws_vpc.mod.id

  tags = {
    Name        = var.name
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_eip" "nat" {
  vpc   = true
  count = length(var.public_subnets)

  tags = {
    Name        = "${var.name}-${element(var.public_subnets, count.index)}-eip"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_nat_gateway" "nat" {
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  count         = length(var.public_subnets)
  depends_on = [
    aws_internet_gateway.mod
  ]

  tags = {
    Name        = "${var.name}-${element(aws_subnet.public.*.id, count.index)}-nat"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.mod.id

  tags = {
    Name        = "${var.name}.public"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.mod.id
  count  = length(var.private_subnets)

  tags = {
    Name        = "${var.name}.private.${element(var.availability_zones, count.index)}"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mod.id
}

resource "aws_route" "nat_gateway" {
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)
  count                  = length(var.public_subnets)

  depends_on = [
    aws_route_table.private
  ]
}

resource "aws_route_table_association" "public" {
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
  count          = length(var.public_subnets)
}

resource "aws_route_table_association" "private" {
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
  count          = length(var.private_subnets)
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.vpc.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.mod.id
}

resource "aws_cloudwatch_log_group" "vpc" {
  name = "${var.environment}-${var.name}"
}

resource "aws_iam_role" "vpc" {
  name = "${var.environment}-${var.name}-vpc-flow-logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpc" {
  name = "${var.environment}-${var.name}-flow-log"
  role = aws_iam_role.vpc.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
