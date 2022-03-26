output "vpc_id" {
  value = try(aws_vpc.main[0].id)
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "intra_subnets" {
  value = aws_subnet.intra[*].id
}
