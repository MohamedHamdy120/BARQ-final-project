resource "aws_elasticache_subnet_group" "main" {
  count      = var.enable_elasticache ? 1 : 0
  name       = "${var.project_name}-cache-subnet-group"
  subnet_ids = aws_subnet.db[*].id
}

resource "aws_security_group" "cache" {
  count       = var.enable_elasticache ? 1 : 0
  name        = "${var.project_name}-cache-sg"
  description = "Redis from nodes only"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-cache-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "redis" {
  count                        = var.enable_elasticache ? 1 : 0
  security_group_id            = aws_security_group.cache[0].id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}

resource "aws_elasticache_replication_group" "main" {
  count                = var.enable_elasticache ? 1 : 0
  replication_group_id = "${var.project_name}-redis"
  description          = "BARQ Redis cache"

  engine               = "redis"
  engine_version       = "7.1"
  parameter_group_name = "default.redis7"
  node_type            = var.cache_node_type
  port                 = 6379

  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  subnet_group_name  = aws_elasticache_subnet_group.main[0].name
  security_group_ids = [aws_security_group.cache[0].id]

  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  auth_token                 = var.cache_auth_token

  snapshot_retention_limit = 1
  apply_immediately        = true

  lifecycle {
    precondition {
      condition     = var.cache_auth_token != null
      error_message = "Set TF_VAR_cache_auth_token when enable_elasticache is true."
    }
  }
}