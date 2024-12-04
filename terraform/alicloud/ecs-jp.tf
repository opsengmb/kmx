resource "alicloud_security_group" "jp-sg" {
  count = var.env_name == "prod" ? 1 : 0
  resource_group_id = alicloud_resource_manager_resource_group.rg.id
  name        = "${var.env_name}-${var.project}-jp-sg"
  description = "${var.env_name}-${var.project} security group"
  vpc_id = module.vpc.vpc_id
}

resource "alicloud_security_group_rule" "jp-https" {
  count = var.env_name == "prod" ? 1 : 0
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.jp-sg[count.index].id
  cidr_ip           = var.vpc_cidr
}

resource "alicloud_security_group_rule" "jp-http-egress" {
  count = var.env_name == "prod" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.jp-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "jp-db-egress" {
  count = var.env_name == "prod" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "3306/3306"
  security_group_id = alicloud_security_group.jp-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "jp-https-egress" {
  count = var.env_name == "prod" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.jp-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "jp-udp-dns-egress" {
  count = var.env_name == "prod" ? 1 : 0
  type              = "egress"
  ip_protocol       = "udp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.jp-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "jp-tcp-dns-egress" {
  count = var.env_name == "prod" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.jp-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_instance" "jobproc_ecs_instance_1" {
  count = var.env_name == "prod" ? 1 : 0
  resource_group_id    = alicloud_resource_manager_resource_group.rg.id 
  instance_name        = "${var.env_name}-${var.project}-jobproc"
  image_id             = var.image_id
  instance_type        = "ecs.g7.large"
  security_groups      = [alicloud_security_group.fe-sg[count.index].id]
  vswitch_id           = module.vpc.vswitch_ids[1]
  password             = "dynamic_random_password"
  system_disk_category = "cloud_essd"
  system_disk_size     = 100
  tags = {
    Name = "${var.env_name}-${var.project}-jobproc"
  }

}
