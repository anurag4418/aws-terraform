variable "aws_region" {
    default = "us-east-1"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "pri_subnet_cidr" {
    type = list
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "pub_subnet_cidr" {
    type = list
    default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "azs" {
    type = list
    default = ["us-east-1a", "us-east-1b"]
}

variable "server_count" {
    default = "2"
}

variable "ami_id" {
    default = "ami-02354e95b39ca8dec"
}

variable "instance_type" {
    default = "t2.micro"
}