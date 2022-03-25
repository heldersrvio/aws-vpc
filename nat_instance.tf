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
  depends_on        = [aws_internet_gateway.igw]
}
