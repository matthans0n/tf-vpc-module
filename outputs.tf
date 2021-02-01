output "private_subnets" {
  value = aws_subnet.private.*.id
}

output "public_subnets" {
  value = aws_subnet.public.*.id
}

output "vpc_id" {
  value = aws_vpc.mod.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_ids" {
  value = aws_route_table.private.*.id
}

output "nat_gateway_public_ips" {
  value = aws_eip.nat.*.public_ip
}

output "vpc_cidr" {
  value = aws_vpc.mod.cidr_block
}

output "vpc_eips" {
  value = formatlist("%s/32", aws_eip.nat.*.public_ip)
}
