output "id" {
  value       = aws_vpc.dev-vpc.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = aws_subnet.dev-pub-subnet.*.id
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.dev-pri-subnet.*.id
  description = "List of private subnet IDs"
}

output "vpc_cidr" {
  value       = var.vpc_cidr
  description = "The CIDR block associated with the VPC"
}

output "nat_gateway_ips" {
  value       = aws_eip.nat-eip.*.public_ip
  description = "List of Elastic IPs associated with NAT gateways"
}

output "jumpserver_hostname" {
  value       = aws_instance.jump-server.public_dns
  description = "Public DNS name for jump server instance"
}

/*
output "webserver_hostname" {
  #count       = var.server_count   
  value       = aws_instance.webserver[count.index].public_dns
  description = "Public DNS name for webserver instance"
}*/

output "elb-dns-name" {
  value       = aws_elb.dev-lb.dns_name
  description = "Public DNS name of LB"
}