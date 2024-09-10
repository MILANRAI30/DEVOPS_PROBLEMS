#The infrastructure requirements are as follows:

#The application will be deployed in three Availability Zones (AZs) in the US East region.

#Each AZ should have an EC2 instance with a minimum of 16GB of RAM and 2 VCPUs.

#The instances should be launched with an SSL certificate for secure communication.

#A load balancer should be configured to distribute traffic across the instances.

#The database should be RDS with automatic backup and multi-AZ deployment.

#The storage should be Elastic Block Store (EBS) with automatic snapshots.

#Write a Terraform configuration file that meets the above requirements, using best practices for Infrastructure as Code (laC) principles.

provider "aws" {
  region = "us-east-1"
}

# Variables
variable "instance_type" {
  default = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}

# Security Group for EC2 instances
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow inbound HTTPS traffic"
  
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

# Launch Configuration for EC2 instances
resource "aws_launch_configuration" "web_lc" {
  image_id            = var.ami_id
  instance_type       = var.instance_type
  security_groups     = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name            = "your-key-name" # Replace with actual key pair name
  
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for EC2 instances
resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_lc.id
  min_size             = 1
  max_size             = 3
  desired_capacity     = 3
  vpc_zone_identifier  = ["subnet-xxxxxxxx", "subnet-yyyyyyyy", "subnet-zzzzzzzz"] # Replace with actual subnet IDs
  health_check_type    = "EC2"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  tag {
    key                 = "Name"
    value               = "web_instance"
    propagate_at_launch = true
  }
}

# Load Balancer
resource "aws_elb" "web_lb" {
  name               = "web-lb"
  availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  security_groups     = [aws_security_group.web_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 443
    lb_protocol       = "HTTPS"
    ssl_certificate_id = var.ssl_certificate_arn
  }
  
  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# RDS Instance
resource "aws_db_instance" "db" {
  engine                  = "mysql"
  instance_class           = "db.t3.medium"
  allocated_storage        = 20
  db_name                  = "media_mix_db"
  username                 = "admin"
  password                 = "password"  # Replace with secure credentials
  multi_az                 = true
  backup_retention_period  = 7
  skip_final_snapshot      = true
}

# EBS Volume for EC2 instances
resource "aws_ebs_volume" "volume" {
  availability_zone = "us-east-1a"
  size              = 50
}

# EBS Snapshot for automatic backup
resource "aws_ebs_snapshot" "snapshot" {
  volume_id = aws_ebs_volume.volume.id
  tags = {
    Name = "media_mix_volume_snapshot"
  }
}
