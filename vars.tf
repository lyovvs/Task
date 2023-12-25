#-----------------------------------------------------------------------#

# Create variables for our main.tf

variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "private_subnet2" {
  default = "10.0.3.0/24"
}

#-----------------------------------------------------------------------#
