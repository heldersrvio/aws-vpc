locals {
  region = "us-east-2"
}

cidr                         = "10.0.0.0/25"
public_subnets               = ["10.0.0.0/29", "10.0.0.9/29", "10.0.0.16/29"]
private_subnets              = ["10.0.0.24/29", "10.0.0.32/29", "10.0.0.40/29"]
intra_subnets                = ["10.0.0.48/29", "10.0.0.56/29", "10.0.0.64/29"]
azs                          = ["${local.region}a", "${local.region}b", "${local.region}c"]
public_subnet_ipv6_prefixes  = [0, 1, 2]
private_subnet_ipv6_prefixes = [3, 4, 5]
intra_subnet_ipv6_prefixes   = [6, 7, 8]
nat_ami_name                 = "nat-instance"
key_pair                     = "ec2-key-pair"
