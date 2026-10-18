output "control_plane_public_ip" {
  value = aws_instance.node["control-plane"].public_ip
}

output "control_plane_private_ip" {
  value = aws_instance.node["control-plane"].private_ip
}

output "worker_public_ip" {
  value = aws_instance.node["worker"].public_ip
}

output "worker_private_ip" {
  value = aws_instance.node["worker"].private_ip
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "app_url" {
  value = "http://${aws_instance.node["worker"].public_ip}:${var.node_port}"
}

output "cache_endpoint" {
  value = one(aws_elasticache_replication_group.main[*].primary_endpoint_address)
}


resource "local_file" "outputs_json" {
  filename = "${path.module}/outputs.json"
  content = jsonencode({
    control_plane_public_ip  = aws_instance.node["control-plane"].public_ip
    control_plane_private_ip = aws_instance.node["control-plane"].private_ip
    worker_public_ip         = aws_instance.node["worker"].public_ip
    worker_private_ip        = aws_instance.node["worker"].private_ip
    rds_endpoint             = aws_db_instance.main.address
    cache_endpoint           = one(aws_elasticache_replication_group.main[*].primary_endpoint_address)
    app_url                  = "http://${aws_instance.node["worker"].public_ip}:${var.node_port}"
  })
}