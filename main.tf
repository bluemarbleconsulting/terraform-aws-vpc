data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------ Locals ------------------
locals {
  selected_azs = slice(
    data.aws_availability_zones.available.names,
    0,
    min(var.desired_number_of_availability_zones, length(data.aws_availability_zones.available.names))
  )
}

# ------------------ VPC ------------------
#trivy:ignore:avd-aws-0178
resource "aws_vpc" "this" {
  assign_generated_ipv6_cidr_block = true
  cidr_block                       = var.ipv4_primary_cidr_block
  enable_dns_hostnames             = true
  enable_dns_support               = true

  tags = merge(
    var.default_tags,
    {
      Name = "${var.namespace}-main"
    },
  )
}

# ------------------ Subnets ------------------
resource "aws_subnet" "public" {
  count                           = length(local.selected_azs)
  assign_ipv6_address_on_creation = true
  availability_zone               = local.selected_azs[count.index]
  cidr_block                      = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, count.index)
  map_public_ip_on_launch         = false
  vpc_id                          = aws_vpc.this.id

  tags = merge(
    var.default_tags,
    {
      Name = "${local.selected_azs[count.index % length(local.selected_azs)]}-main-public"
      Type = "public"
    }
  )

  lifecycle {
    ignore_changes = [cidr_block]
  }
}

resource "aws_subnet" "private" {
  count                           = length(local.selected_azs)
  assign_ipv6_address_on_creation = true
  availability_zone               = local.selected_azs[count.index]
  cidr_block                      = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index + length(local.selected_azs))
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, count.index + length(local.selected_azs))
  map_public_ip_on_launch         = false
  vpc_id                          = aws_vpc.this.id

  tags = merge(
    var.default_tags,
    {
      Name = "${local.selected_azs[count.index % length(local.selected_azs)]}-main-private"
      Type = "private"
    }
  )

  lifecycle {
    ignore_changes = [cidr_block]
  }
}

# ------------------ Internet Gateway ------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.default_tags,
    {
      Name = "main-igw"
    }
  )
}

# ------------------ Egress-Only Internet Gateway ------------------
resource "aws_egress_only_internet_gateway" "main" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.default_tags,
    {
      Name = "main-eigw"
    }
  )
}


# ------------------ Route Tables ------------------
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.this.default_route_table_id
  tags                   = var.default_tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  route {
    cidr_block = aws_vpc.this.cidr_block
    gateway_id = "local"
  }

  route {
    ipv6_cidr_block = aws_vpc.this.ipv6_cidr_block
    gateway_id      = "local"
  }

  tags = merge(
    var.default_tags,
    {
      Name = "public-main-rt"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    egress_only_gateway_id = aws_egress_only_internet_gateway.main.id
    ipv6_cidr_block        = "::/0"
  }

  route {
    cidr_block = aws_vpc.this.cidr_block
    gateway_id = "local"
  }

  route {
    ipv6_cidr_block = aws_vpc.this.ipv6_cidr_block
    gateway_id      = "local"
  }

  tags = merge(
    var.default_tags,
    {
      Name = "private-main-rt"
    }
  )
}

# ------------------ Route Table Associations ------------------
resource "aws_route_table_association" "public_rt_association" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  depends_on     = [aws_internet_gateway.main]
}

resource "aws_route_table_association" "private_rt_association" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ------------------ Default Security Group ------------------
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
  tags   = var.default_tags
}
