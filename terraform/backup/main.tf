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
      Purpose     = "DisasterRecovery"
    }
  }
}

# S3 Bucket for Database Backups
resource "aws_s3_bucket" "db_backups" {
  bucket = "${var.project_name}-db-backups-${var.environment}-${data.aws_caller_identity.current.account_id}"
  tags   = { Name = "${var.project_name}-db-backups-${var.environment}" }
}

resource "aws_s3_bucket_versioning" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket for EC2 Snapshots/AMI metadata
resource "aws_s3_bucket" "ec2_backups" {
  bucket = "${var.project_name}-ec2-backups-${var.environment}-${data.aws_caller_identity.current.account_id}"
  tags   = { Name = "${var.project_name}-ec2-backups-${var.environment}" }
}

resource "aws_s3_bucket_versioning" "ec2_backups" {
  bucket = aws_s3_bucket.ec2_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket for Application Data
resource "aws_s3_bucket" "app_backups" {
  bucket = "${var.project_name}-app-backups-${var.environment}-${data.aws_caller_identity.current.account_id}"
  tags   = { Name = "${var.project_name}-app-backups-${var.environment}" }
}

resource "aws_s3_bucket_versioning" "app_backups" {
  bucket = aws_s3_bucket.app_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy to move old backups to cheaper storage
resource "aws_s3_bucket_lifecycle_configuration" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id

  rule {
    id     = "archive-old-backups"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

data "aws_caller_identity" "current" {}
