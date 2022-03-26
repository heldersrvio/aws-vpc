data "aws_caller_identity" "current" {}

data "aws_ami" "nat_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.nat_ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [data.aws_caller_identity.current.account_id]
}

resource "aws_security_group" "nat_sg" {
  name        = "nat-sg"
  description = "Allow internet-bound traffic from private subnets"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description      = "Inbound traffic from private subnets"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = aws_subnet.private[*].cidr_block
    ipv6_cidr_blocks = aws_subnet.private[*].ipv6_cidr_block
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "nat" {
  ami                         = data.aws_ami.nat_ami.id
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = var.key_pair
  subnet_id = element(
    aws_subnet.public[*].id,
    0,
  )
  source_dest_check = false
  security_groups   = [aws_security_group.nat_sg.id]
  depends_on        = [aws_internet_gateway.igw]

  tags = {
    "Name" = "nat-instance"
  }
}

resource "aws_route" "nat_instance_route" {
  count = 1

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(
    aws_route_table.private[*].id,
    0,
  )
}
