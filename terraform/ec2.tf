data "aws_ami" "centos" {
  most_recent = true
  owners      = ["125523088429"] # CentOS Project
  filter {
    name   = "name"
    values = ["CentOS Stream 10 x86_64 *"]
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)
}

locals {
  nodes = {
    control-plane = { volume_size = 20 }
    worker        = { volume_size = 30 }
  }
}

resource "aws_instance" "node" {
  for_each               = local.nodes
  ami                    = data.aws_ami.centos.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.nodes.id]
  key_name               = aws_key_pair.main.key_name
  iam_instance_profile   = aws_iam_instance_profile.node.name

  metadata_options {
    http_tokens = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size = each.value.volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-${each.key}"
    Role = each.key
  }

  lifecycle {
    ignore_changes = [ami]
  }
}