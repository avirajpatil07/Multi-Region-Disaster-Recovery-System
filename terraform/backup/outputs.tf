output "db_backup_bucket" {
  value = aws_s3_bucket.db_backups.id
}

output "ec2_backup_bucket" {
  value = aws_s3_bucket.ec2_backups.id
}

output "app_backup_bucket" {
  value = aws_s3_bucket.app_backups.id
}

output "backup_region" {
  value = var.aws_region
}
