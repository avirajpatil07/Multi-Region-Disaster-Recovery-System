variable "aws_region" {
  description = "Backup AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "dr-ecom-v2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "backup"
}
