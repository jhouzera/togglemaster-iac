locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_region" "current" {}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Allow PostgreSQL access within VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "auth" {
  identifier              = "${local.name_prefix}-auth-db"
  engine                  = "postgres"
  engine_version          = "16.3"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 20
  storage_type            = "gp3"
  db_name                 = "auth_db"
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
}

resource "aws_db_instance" "flag" {
  identifier              = "${local.name_prefix}-flag-db"
  engine                  = "postgres"
  engine_version          = "16.3"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 20
  storage_type            = "gp3"
  db_name                 = "flags_db"
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
}

resource "aws_db_instance" "targeting" {
  identifier              = "${local.name_prefix}-targeting-db"
  engine                  = "postgres"
  engine_version          = "16.3"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 20
  storage_type            = "gp3"
  db_name                 = "targeting_db"
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
}

resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Allow Redis access within VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name_prefix}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.project_name}-${var.environment}-redis"
  description                = "Redis for evaluation service"
  node_type                  = "cache.t4g.micro"
  engine                     = "redis"
  engine_version             = "7.1"
  parameter_group_name       = "default.redis7"
  port                       = 6379
  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false
  at_rest_encryption_enabled = false
  transit_encryption_enabled = false
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.redis.id]
}

resource "aws_dynamodb_table" "analytics" {
  name         = "${local.name_prefix}-analytics-events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }
}

resource "aws_sqs_queue" "events" {
  name                       = "${local.name_prefix}-evaluation-events"
  fifo_queue                 = false
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 30
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${local.name_prefix}/app/config"
  description             = "Segredos e endpoints de runtime do ToggleMaster"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    auth_database_url      = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.auth.address}:5432/auth_db"
    flag_database_url      = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.flag.address}:5432/flags_db"
    targeting_database_url = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.targeting.address}:5432/targeting_db"
    redis_url              = "redis://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
    aws_sqs_url            = aws_sqs_queue.events.url
    aws_sqs_arn            = aws_sqs_queue.events.arn
    dynamodb_table_name    = aws_dynamodb_table.analytics.name
    aws_region             = data.aws_region.current.name
    service_api_key        = var.service_api_key
    master_key             = var.master_key
  })
}

