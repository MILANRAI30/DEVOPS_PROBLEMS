#Write a Terraform configuration file that deploys the following resources:

#A VPC with a public subnet in each AZ

#A security group that allows inbound traffic on port 80

#An Application Load Balancer (ALB) that routes traffic to the web application

#An Auto Scaling Group (ASG) that launches instances in each AZ

#A relational database instance (RDS) with a read replica in each AZ

#An S3 bucket to store application logs


# Define provider
provider "aws" {
  region = "us-east-1"
}

# Define variables
variable "department" {
  description = "Department name for resource tagging"
  default     = "healthcare"
}

variable "environment" {
  description = "Environment name for resource tagging"
  default     = "prod"
}

# Define VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
    department = var.department
    environment = var.environment
  }
}

# Define subnets
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
    department = var.department
    environment = var.environment
  }
}

# Define security group
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "web-sg"
    department = var.department
    environment = var.environment
  }
}

# Define Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "web-alb"
    department = var.department
    environment = var.environment
  }
}

# Define Auto Scaling Group
resource "aws_launch_configuration" "web_lc" {
  name          = "web-launch-configuration"
  image_id      = "ami-0c55b159cbfafe1f0" # Replace with appropriate AMI ID
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.id]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "web-instance"
    department = var.department
    environment = var.environment
  }
}

resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_lc.id
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = aws_subnet.public[*].id
  health_check_type    = "EC2"
  health_check_grace_period = "300"

  tag {
    key                 = "Name"
    value               = "web-instance"
    propagate_at_launch = true
  }

  tags = {
    department = var.department
    environment = var.environment
  }
}

# Define RDS instance
resource "aws_db_instance" "web_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  name                 = "webdb"
  username             = "admin"
  password             = "password" # Change to a secure password
  multi_az             = true
  backup_retention_period = 7
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  db_subnet_group_name = aws_db_subnet_group.web_db_subnet_group.id

  tags = {
    Name = "web-db"
    department = var.department
    environment = var.environment
  }
}

# Define RDS Read Replica
resource "aws_db_instance" "web_db_replica" {
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  source_db_instance_identifier = aws_db_instance.web_db.id
  publicly_accessible  = false

  tags = {
    Name = "web-db-replica"
    department = var.department
    environment = var.environment
  }
}

# Define DB subnet group
resource "aws_db_subnet_group" "web_db_subnet_group" {
  name       = "web-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "web-db-subnet-group"
    department = var.department
    environment = var.environment
  }
}

# Define S3 bucket for application logs
resource "aws_s3_bucket" "app_logs" {
  bucket = "app-logs-${var.department}-${var.environment}"
  acl    = "private"

  tags = {
    Name = "app-logs"
    department = var.department
    environment = var.environment
  }
}
