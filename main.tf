provider "aws" {
    region = "us-east-1"
    access_key = ""
    secret_key = ""
}

variable "dev-vpc_cidr_block" {
  description = "vpc cidr block range"
  type = string
}

variable "dev-subnet-1_cidr_block" {
  description = "subnet-1 cidr block range"
  type = string
}

resource "aws_vpc" "dev-vpc" {
  cidr_block = var.dev-vpc_cidr_block 
 tags = {
    Name: "development-vpc"
 }
} 


resource "aws_subnet" "dev-subnet-1"{
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.dev-subnet-1_cidr_block
    availability_zone = "us-east-1a"
     tags = {
    Name: "dev-subnet1"
 }
}

data "aws_vpc" "existing_dev_vpc" {
   default = true 
}

output "dev-vpc-id" {
    value = aws_vpc.dev-vpc.id
}

output "dev-subnet-id" {
    value = aws_subnet.dev-subnet-1.id
}
