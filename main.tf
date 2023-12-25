#-----------------------------------------------------------------------#

# Create provider

provider "aws" {
  region = var.region
}

#-----------------------------------------------------------------------#

# Create a terraform remote state

terraform {
  backend "s3" {
    bucket  = "levon-aslanyan-task-terraform-state"
    key     = "dev/network/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

#-----------------------------------------------------------------------#

# Create a VPC

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my_vpc"
  }
}

#-----------------------------------------------------------------------#

# Create public subnet

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

#-----------------------------------------------------------------------#

# Security group for public subnet

resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.main.id

  # Allow inbound traffic on ports 80 (HTTP) and 443 (HTTPS) from anywhere

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#-----------------------------------------------------------------------#

# Create private subnets

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet2
  availability_zone = "us-east-1c"

  tags = {
    Name = "private-subnet-us-east-1c"
  }
}

#-----------------------------------------------------------------------#

# Create security group for private subnets

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.main.id

  ingress = [
    {
      from_port        = 3306
      to_port          = 3306
      protocol         = "tcp"
      cidr_blocks      = ["10.0.0.0/16"]
      description      = "MySQL traffic"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "All traffic"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}

#-----------------------------------------------------------------------#

# Create IGW

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

#-----------------------------------------------------------------------#

# Create route table for public subnets

resource "aws_route_table" "public_subnet" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Route table for public subnet"
  }
}

#-----------------------------------------------------------------------#

# Create route table association

resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnet[*].id)
  route_table_id = aws_route_table.public_subnet.id
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
}

#-----------------------------------------------------------------------#

# Create RDS instance and AWS_db_subnet_group

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name        = "my-db-subnet-group"
  description = "My DB subnet group"
  subnet_ids  = [aws_subnet.private_subnet.id, aws_subnet.private_subnet2.id]
}

resource "aws_db_instance" "my_rds" {
  identifier             = "my-rds-instance"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "admin123"
  parameter_group_name   = "default.mysql5.7"
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
}

#-----------------------------------------------------------------------#

# Create Auto Scaling Group 

resource "aws_launch_configuration" "example" {
  image_id        = "ami-079db87dc4c10ac91"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.private_sg.id]
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  vpc_zone_identifier  = [aws_subnet.public_subnet.id, element(aws_subnet.private_subnet.*.id, 0)]
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
}

#-----------------------------------------------------------------------#

# Outputs 

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the created public subnet"
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "The ID of the created private subnet"
  value       = aws_subnet.private_subnet.id
}

output "rds_endpoint" {
  description = "The endpoint of the created RDS instance"
  value       = aws_db_instance.my_rds.endpoint
}

output "autoscaling_group_name" {
  description = "The name of the created Auto Scaling Group"
  value       = aws_autoscaling_group.example.name
}

output "launch_configuration_id" {
  description = "The ID of the created Launch Configuration"
  value       = aws_launch_configuration.example.id
}

#-----------------------------------------------------------------------#

