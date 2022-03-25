variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
}

variable "intra_subnets" {
  description = "A list of intra subnets inside the VPC"
  type        = list(string)
}

variable "azs" {
  description = "A list of availability zones"
  type        = list(string)
}

variable "private_subnet_ipv6_prefixes" {
  description = "Assigns IPv6 private subnet id based on the Amazon provided /56 prefix base 10 integer (0-256)."
  type        = list(string)
}

variable "public_subnet_ipv6_prefixes" {
  description = "Assigns IPv6 public subnet id based on the Amazon provided /56 prefix base 10 integer (0-256)."
  type        = list(string)
}

variable "intra_subnet_ipv6_prefixes" {
  description = "Assigns IPv6 intra subnet id based on the Amazon provided /56 prefix base 10 integer (0-256)."
  type        = list(string)
}

variable "nat_ami_name" {
  description = "The name of the AMI for the NAT instance"
  type        = string
}

variable "key_pair" {
  description = "A key pair name for the NAT instance"
  type        = string
}
