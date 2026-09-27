output "vpc_id" {
  value = aws_vpc.main.id
}

output "web_instance_id" {
  value = aws_instance.web.id
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "s3_bucket" {
  value = aws_s3_bucket.data.id
}
