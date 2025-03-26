provider "aws" {
    region = "us-east-1"
    access_key = ""
    secret_key = ""
}

variable "vpc_cidr_block" {
  description = "vpc cidr block range"
}

variable "subnet-1_cidr_block" {
  description = "subnet-1 cidr block range"
}

variable "avail_zone" {
  description = "subnet-1 availability zone"
}
variable env_prefix {}
variable my_ip{}

resource "aws_vpc" "nodejs-app-vpc" {
  cidr_block = var.vpc_cidr_block 
 tags = {
    Name: "${var.env_prefix}-vpc"
 }
} 


resource "aws_subnet" "nodejs-app-subnet"{
    vpc_id = aws_vpc.nodejs-app-vpc.id
    cidr_block = var.subnet-1_cidr_block
    availability_zone = var.avail_zone
     tags = {
    Name: "${var.env_prefix}-subnet1"
 }
}

data "aws_vpc" "existing-dev-vpc" {
   default = true 
}

output "nodejs-app-vpc-id" {
    value = aws_vpc.nodejs-app-vpc.id
}

output "nodejs-app-subnet-id" {
    value = aws_subnet.nodejs-app-subnet.id
}

resource "aws_route_table" "nodejs-app-route-table" {
  vpc_id = aws_vpc.nodejs-app-vpc.id
   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nodejs-app-igw.id
   }

   tags = {
    Name: "${var.env_prefix}-rtb"
   }

}

resource "aws_internet_gateway" "nodejs-app-igw" {
  vpc_id = aws_vpc.nodejs-app-vpc.id

    tags = {
    Name: "${var.env_prefix}-igw"
   }
}

resource "aws_route_table_association" "nodejs-app-subnet-rtb-a"{
  subnet_id = aws_subnet.nodejs-app-subnet.id
  route_table_id = aws_route_table.nodejs-app-route-table.id
}

resource "aws_security_group" "nodejs-app-sg" {
  name =  "nodejs-app-sg"
  vpc_id = aws_vpc.nodejs-app-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

   ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

    tags = {
    Name: "${var.env_prefix}-sg"
   }
}
