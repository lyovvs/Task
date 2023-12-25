# Task Description

# Task 
  
  Create VPC private public subnets autoscaling min 1 instance max 2 rds mysql. 

# Solution

I created a VPC with 1 public and 2 private subnets along with their public and private security groups,also created internet gateway,route table with it's association for public routes.

Also created a terraform remote state to save my statefile in s3 bucket remotely.

At the end was created aws_db_instance my_rds with mySQL database with autoscaling group of min:1 and max:2 

#------------------------------------------------------#


