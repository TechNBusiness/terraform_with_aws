# define the resource providers for the infrastructure 
provider "aws" {
    region = "us-east-1"
    access_key = ""
    secret_key = ""
}

# Define usable variables in the code and declare the values in the tfvars file 
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
variable instance_type{}
variable key_pair{}

# Create a separate vpc for a demoapp
resource "aws_vpc" "nodejs-app-vpc" {
  cidr_block = var.vpc_cidr_block 
 tags = {
    Name: "${var.env_prefix}-vpc"
 }
} 

# Create a subnet for a demoapp and attach to the nodejs-app vpc
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

# Output the vpc id of the new vpc resource
output "nodejs-app-vpc-id" {
    value = aws_vpc.nodejs-app-vpc.id
}
# Output the subnet id of the new subnet resource
output "nodejs-app-subnet-id" {
    value = aws_subnet.nodejs-app-subnet.id
}

# Create a route table for a demoapp and attach to the nodejs-app vpc
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

# Create an internet gateway for a demoapp to allow public traffic to-and-fro and attach to the nodejs-app vpc
resource "aws_internet_gateway" "nodejs-app-igw" {
  vpc_id = aws_vpc.nodejs-app-vpc.id

    tags = {
    Name: "${var.env_prefix}-igw"
   }
}

# Create a route table association for a demoapp and attach to the nodejs-app subnet
resource "aws_route_table_association" "nodejs-app-subnet-rtb-a"{
  subnet_id = aws_subnet.nodejs-app-subnet.id
  route_table_id = aws_route_table.nodejs-app-route-table.id
}

# Create a security group for a demoapp and attach to the nodejs-app vpc
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

# Query aws provider for the latest amazon linux image
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

   filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}


# Create an EC2 instance for a demoapp using amazon linux image and run Docker on it
resource "aws_instance" "nodejs-app-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.nodejs-app-subnet.id
  vpc_security_group_ids = [aws_security_group.nodejs-app-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = var.key_pair

  user_data = file("entry-script.sh")

  tags = {
    Name: "${var.env_prefix}-server"
  }
}

# Output the machine image id of the new server instance
output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

# Output the public ip address of the new server instance
output "ec2_public_ip" {
  value = aws_instance.nodejs-app-server
}
