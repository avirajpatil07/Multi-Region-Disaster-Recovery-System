terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.project_name}-vpc-${var.environment}" }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw-${var.environment}" }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-${var.environment}" }
}

# Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "${var.project_name}-private-1-${var.environment}" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "${var.project_name}-private-2-${var.environment}" }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-rt-${var.environment}" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group - Web
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg-${var.environment}"
  description = "Web server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = { Name = "${var.project_name}-web-sg-${var.environment}" }
}

# Security Group - Database
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg-${var.environment}"
  description = "Database security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-db-sg-${var.environment}" }
}

# SSH Key
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key-${var.environment}"
  public_key = file("~/.ssh/id_rsa.pub")
}

# AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = <<-USERDATA
              #!/bin/bash
              yum update -y
              yum install -y httpd php php-mysqlnd mysql
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>DR E-commerce - Primary (${var.aws_region})</h1>" > /var/www/html/index.html
              USERDATA

  tags = { Name = "${var.project_name}-web-${var.environment}" }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-${var.environment}"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags       = { Name = "${var.project_name}-db-subnet-${var.environment}" }
}

# RDS MySQL 5.7
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db-${var.environment}"
  engine         = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.micro"
  
  allocated_storage = 20
  storage_type      = "gp3"
  
  db_name  = "ecommerce"
  username = var.db_username
  password = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  
  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  
  skip_final_snapshot = true
  
  tags = { Name = "${var.project_name}-db-${var.environment}" }
}

# S3 Bucket
resource "aws_s3_bucket" "data" {
  bucket = "${var.project_name}-data-${var.environment}-${data.aws_caller_identity.current.account_id}"
  tags   = { Name = "${var.project_name}-data-${var.environment}" }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_caller_identity" "current" {}
