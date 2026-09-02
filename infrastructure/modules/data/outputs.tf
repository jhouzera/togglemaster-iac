output "auth_rds_endpoint" {
  value = aws_db_instance.auth.address
}

output "flag_rds_endpoint" {
  value = aws_db_instance.flag.address
}

output "targeting_rds_endpoint" {
  value = aws_db_instance.targeting.address
}

output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.events.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.events.url
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.analytics.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.analytics.arn
}
