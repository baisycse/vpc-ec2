terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "my-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc-virginia"
  }
}

resource "aws_subnet" "publicsubnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "publicsub-virginia"
  }
}

resource "aws_subnet" "privatesubnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "privatesub-virginia"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "igw-virginia"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

   tags = {
    Name = "pubrt-virginia"
  }
}

resource "aws_route_table_association" "pub-association" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_eip" "my-eip" {
    vpc      = true
}

resource "aws_nat_gateway" "my-nat" {
  allocation_id = aws_eip.my-eip.id
  subnet_id     = aws_subnet.publicsubnet.id

  tags = {
    Name = "nat-virginia"
  }
  
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-nat.id
  }

   tags = {
    Name = "privatert-virginia"
  }
}

resource "aws_route_table_association" "pri-association" {
  subnet_id      = aws_subnet.privatesubnet.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

     
  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "virginia-sg"
  }
}

resource "aws_instance" "publicec2" {
  ami                            =  "ami-04ad2567c9e3d7893"
  instance_type                  =  "t2.micro"
  subnet_id                      =  aws_subnet.publicsub.id
  key_name                       =  "linux-virginia"
  vpc_security_group_ids         =  [aws_security_group.allow_all.id]
  associate_public_ip_address    =  true
}

resource "aws_instance" "privateec2" {
  ami                            =  "ami-04ad2567c9e3d7893"
  instance_type                  =  "t2.micro"
  subnet_id                      =  aws_subnet.privatesub.id
  key_name                       =  "linux-virginia"
  vpc_security_group_ids         =  [aws_security_group.allow_all.id]
  associate_public_ip_address    =  true
}