locals {
  node_internal_rules = {
    api-server = { protocol = "tcp", from = 6443, to = 6443 }
    etcd       = { protocol = "tcp", from = 2379, to = 2380 }
    kubelet    = { protocol = "tcp", from = 10250, to = 10250 }
    cni-vxlan  = { protocol = "udp", from = 8472, to = 8472 } # Flannel
  }
}

resource "aws_security_group" "nodes" {
  name        = "${var.project_name}-nodes-sg"
  description = "Kubernetes nodes"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-nodes-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each          = toset(var.allowed_ssh_cidrs)
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "internal" {
  for_each                     = local.node_internal_rules
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.from
  to_port                      = each.value.to
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  for_each          = toset(var.app_access_cidrs)
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.node_port
  to_port           = var.node_port
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "PostgreSQL from nodes only"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-rds-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}