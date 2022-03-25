locals {
  public_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]

  public_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]

  private_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]

  private_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]

  intra_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]

  intra_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

resource "aws_vpc" "main" {
  count = 1

  cidr_block                       = var.cidr
  enable_dns_hostnames             = false
  enable_dns_support               = false
  assign_generated_ipv6_cidr_block = true
}

resource "aws_internet_gateway" "igw" {
  count = 1

  vpc_id = aws_vpc.main[0].id
}

resource "aws_egress_only_internet_gateway" "egress_only_igw" {
  count = 1

  vpc_id = aws_vpc.main[0].id
}

resource "aws_route_table" "public" {
  count = 1

  vpc_id = aws_vpc.main[0].id
}

resource "aws_route" "public_internet_gateway" {
  count = 1

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

resource "aws_route" "public_internet_gateway_ipv6" {
  count = 1

  route_table_id              = aws_route_table.public[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.igw[0].id
}

resource "aws_route_table" "private" {
  count = 1

  vpc_id = aws_vpc.main[0].id
}

resource "aws_route" "private_ipv6_egress" {
  count = length(var.private_subnets)

  route_table_id              = element(aws_route_table.private[*].id, count.index)
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = element(aws_egress_only_internet_gateway.egress_only_igw[*].id, 0)
}

resource "aws_route_table" "intra" {
  count = 1

  vpc_id = aws_vpc.main[0].id
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                          = aws_vpc.main[0].id
  cidr_block                      = element(concat(var.public_subnets, [""]), count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  ipv6_cidr_block = cidrsubnet(aws_vpc.main[0].ipv6_cidr_block, 8, var.public_subnet_ipv6_prefixes[count.index])
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id                          = aws_vpc.main[0].id
  cidr_block                      = var.private_subnets[count.index]
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  assign_ipv6_address_on_creation = true

  ipv6_cidr_block = cidrsubnet(aws_vpc.main[0].ipv6_cidr_block, 8, var.private_subnet_ipv6_prefixes[count.index])
}

resource "aws_subnet" "intra" {
  count = length(var.intra_subnets)

  vpc_id                          = aws_vpc.main[0].id
  cidr_block                      = var.intra_subnets[count.index]
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  assign_ipv6_address_on_creation = true

  ipv6_cidr_block = cidrsubnet(aws_vpc.main[0].ipv6_cidr_block, 8, var.intra_subnet_ipv6_prefixes[count.index])
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "intra" {
  count = length(var.intra_subnets)

  subnet_id      = element(aws_subnet.intra[*].id, count.index)
  route_table_id = element(aws_route_table.intra[*].id, 0)
}

resource "aws_network_acl" "public_network_acl" {
  count = 1

  vpc_id     = aws_vpc.main[0].id
  subnet_ids = aws_subnet.public[*].id
}

resource "aws_network_acl_rule" "public_inbound" {
  count = length(local.public_inbound_acl_rules)

  network_acl_id = aws_network_acl.public_network_acl[0].id

  egress          = false
  rule_number     = local.public_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = local.public_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(local.public_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(local.public_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(local.public_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(local.public_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = local.public_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(local.public_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(local.public_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "public_outbound" {
  count = length(local.public_outbound_acl_rules)

  network_acl_id = aws_network_acl.public_network_acl[0].id

  egress          = true
  rule_number     = local.public_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = local.public_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(local.public_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(local.public_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(local.public_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(local.public_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = local.public_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(local.public_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(local.public_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl" "private" {
  count = length(var.private_subnets)

  vpc_id     = aws_vpc.main[0].id
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_network_acl_rule" "private_inbound" {
  count = length(local.private_inbound_acl_rules)

  network_acl_id = aws_network_acl.private[0].id

  egress          = false
  rule_number     = local.private_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = local.private_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(local.private_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(local.private_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(local.private_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(local.private_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = local.private_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(local.private_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(local.private_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  count = length(local.private_outbound_acl_rules)

  network_acl_id = aws_network_acl.private[0].id

  egress          = true
  rule_number     = local.private_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = local.private_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(local.private_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(local.private_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(local.private_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(local.private_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = local.private_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(local.private_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(local.private_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl" "intra" {
  count = length(var.intra_subnets)

  vpc_id     = aws_vpc.main[0].id
  subnet_ids = aws_subnet.intra[*].id
}

resource "aws_network_acl_rule" "intra_inbound" {
  count = length(local.intra_inbound_acl_rules)

  network_acl_id = aws_network_acl.intra[0].id

  egress          = false
  rule_number     = local.intra_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = local.intra_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(local.intra_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(local.intra_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(local.intra_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(local.intra_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = local.intra_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(local.intra_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(local.intra_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "intra_outbound" {
  count = length(local.intra_outbound_acl_rules)

  network_acl_id = aws_network_acl.intra[0].id

  egress          = true
  rule_number     = local.intra_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = local.intra_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(local.intra_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(local.intra_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(local.intra_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(local.intra_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = local.intra_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(local.intra_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(local.intra_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}
