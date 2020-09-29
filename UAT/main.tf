provider "aws" {
  region     = var.aws_region
}

# Create a VPC
resource "aws_vpc" "uat-vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
   Name = "uat-vpc"
  }
}

# Create a Internet Gateway
resource "aws_internet_gateway" "uat-igw" {
  vpc_id = aws_vpc.uat-vpc.id
  tags = {
    Name = "uat-igw"
  }
}

# Create a Public Subnet
resource "aws_subnet" "uat-pub-subnet" {
  count      = length(var.pub_subnet_cidr)  
  vpc_id     = aws_vpc.uat-vpc.id
  cidr_block = var.pub_subnet_cidr[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    Name = "public-subnet-${count.index+1}"
  }
}

# Create a Public Route Table
resource "aws_route_table" "uat-pub-rt" {
  vpc_id = aws_vpc.uat-vpc.id
  tags = {
    Name = "uat-pub-rt"
  }  
}

# Create a Public Route
resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.uat-pub-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.uat-igw.id
}

# Create a Public Route Table Association
resource "aws_route_table_association" "pub-rt-association" {
  count          = length(var.pub_subnet_cidr)   

  subnet_id      = aws_subnet.uat-pub-subnet[count.index].id
  route_table_id = aws_route_table.uat-pub-rt.id
  #subnet_id      = element(aws_subnet.uat-pub-subnet.*.id,count.index)
  #route_table_id = aws_route_table.uat-pub-rt.id
}

# Create a NAT Gateway resource
resource "aws_eip" "nat-eip" {
  count = length(var.pub_subnet_cidr)

  vpc = true
}

# Create a NAT Gateway
resource "aws_nat_gateway" "uat-nat" {
  depends_on = [aws_internet_gateway.uat-igw]

  count = length(var.pub_subnet_cidr)

  allocation_id = aws_eip.nat-eip[count.index].id
  subnet_id     = aws_subnet.uat-pub-subnet[count.index].id

}

# Create a Private Subnet
resource "aws_subnet" "uat-pri-subnet" {
  count      = length(var.pri_subnet_cidr)  
  vpc_id     = aws_vpc.uat-vpc.id
  cidr_block = var.pri_subnet_cidr[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    Name = "private-subnet-${count.index+1}"
  }
}

# Create a Private Route Table
resource "aws_route_table" "uat-pri-rt" {
  #count = length(var.pri_subnet_cidr)

  vpc_id = aws_vpc.uat-vpc.id

  tags = {
    Name = "uat-pri-rt"
  }
}

# Create a Private Route
resource "aws_route" "private-route" {
  count = length(var.pri_subnet_cidr)

  route_table_id         = aws_route_table.uat-pri-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.uat-nat[count.index].id
}

# Create a Private Route Table Association
resource "aws_route_table_association" "pri-rt-association" {
  count = length(var.pri_subnet_cidr)

  subnet_id      = aws_subnet.uat-pri-subnet[count.index].id
  route_table_id = aws_route_table.uat-pri-rt.id
}

# Create a Jump Server Security Group
resource "aws_security_group" "uat-jump-secgroup" {
  name        = "uat-jump-secgroup"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.uat-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uat-secgroup"
  }
}


# Create a Webserver Security Group
resource "aws_security_group" "uat-web-secgroup" {
  name        = "uat-secgroup"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.uat-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uat-web-secgroup"
  }
}

# Create a Jump Server
resource "aws_instance" "jump-server" {
  ami                         = var.ami_id
  availability_zone           = var.azs[0]
  instance_type               = var.instance_type
  key_name                    = "nVirginia-key"
  vpc_security_group_ids   = [aws_security_group.uat-jump-secgroup.id]
  subnet_id                   = aws_subnet.uat-pub-subnet[0].id
  associate_public_ip_address = true

  tags =   {
      Name        = "Jump-server"
    }
}

/*
# Create a Web Server
resource "aws_instance" "webservers" {
  count         = var.server_count  
  ami           = var.ami_id
  instance_type = var.instance_type
  availability_zone = var.azs[count.index]
  key_name = "nVirginia-key"
  vpc_security_group_ids   = [aws_security_group.uat-web-secgroup.id]
  subnet_id         = aws_subnet.uat-pri-subnet[count.index].id
  user_data         = file("install_httpd.sh")

  tags =   {
    Name        = "webserver-${count.index+1}"
  }
}  */

# Define AutoScalling Launch Configuration

resource "aws_launch_configuration" "uat-launch-config" {
  image_id           = var.ami_id
  instance_type = var.instance_type
  security_groups = [aws_security_group.uat-web-secgroup.id]
  user_data         = file("install_httpd.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "uat-asgroup" {
  launch_configuration = aws_launch_configuration.uat-launch-config.name
  vpc_zone_identifier  = [aws_subnet.uat-pri-subnet[0].id, aws_subnet.uat-pri-subnet[1].id]

  min_size = 2
  max_size = 5

  tag {
    key                 = "Name"
    value               = "webservers"
    propagate_at_launch = true
  }
}

# Create a ELB
resource "aws_elb" "uat-lb" {
  name = "uat-lb"
  subnets = aws_subnet.uat-pub-subnet.*.id
  security_groups = [aws_security_group.uat-jump-secgroup.id]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  #instances = aws_instance.webservers.*.id
  cross_zone_load_balancing = true
  idle_timeout = 100
  connection_draining = true
  connection_draining_timeout = 100

  tags = {
    Name = "uat-lb"
  }

}

# Create a Auto Scalling Group Attachment
resource "aws_autoscaling_attachment" "asg_attachment_uat" {
  autoscaling_group_name = aws_autoscaling_group.uat-asgroup.id
  elb                    = aws_elb.uat-lb.id
}