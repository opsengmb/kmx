resource "alicloud_slb_load_balancer" "clb" {
  count = var.env_name == "dev" ? 1 : 0
  load_balancer_name = "${var.env_name}-${var.project}-clb"
  address_type       = "internet"
  load_balancer_spec = "slb.s2.small"
  vswitch_id         = module.vpc.vpc_id
  tags = {
    info = "create for internet"
  }
  instance_charge_type = "PayBySpec"
}


resource "alicloud_slb_server_group" "default" {
  count = var.env_name == "dev" ? 1 : 0
  load_balancer_id = alicloud_slb_load_balancer.clb.id
  name             = "${var.env_name}-${var.project}-clb-server-attachment"
}

resource "alicloud_slb_server_group_server_attachment" "server_attachment" {
  count = var.env_name == "dev" ? 1 : 0
  server_group_id = alicloud_slb_server_group.default.id
  server_id       = alicloud_instance.dev_ecs_instance_1[count.index].id
  port            = 8080
  weight          = 0
}


resource "alicloud_security_group" "dev-sg" {
  count = var.env_name == "dev" ? 1 : 0
  resource_group_id = alicloud_resource_manager_resource_group.rg.id
  name        = "${var.env_name}-${var.project}-dev-sg"
  description = "${var.env_name}-${var.project} security group"
  vpc_id = module.vpc.vpc_id
}

resource "alicloud_security_group_rule" "dev-http" {
  count = var.env_name == "dev" ? 1 : 0
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "8080/8080"
  security_group_id = alicloud_security_group.dev-sg[count.index].id
  cidr_ip           = var.vpc_cidr
}

resource "alicloud_security_group_rule" "dev-http-egress" {
  count = var.env_name == "dev" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.dev-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "dev-db-egress" {
  count = var.env_name == "dev" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "3306/3306"
  security_group_id = alicloud_security_group.dev-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "dev-https-egress" {
  count = var.env_name == "dev" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.dev-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "dev-udp-dns-egress" {
  count = var.env_name == "dev" ? 1 : 0
  type              = "egress"
  ip_protocol       = "udp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.dev-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "dev-tcp-dns-egress" {
  count = var.env_name == "dev" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.dev-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_instance" "dev_ecs_instance_1" {
  count = var.env_name == "dev" ? 1 : 0
  resource_group_id    = alicloud_resource_manager_resource_group.rg.id 
  instance_name        = "${var.env_name}-${var.project}-dev-test"
  image_id             = "ubuntu_24_04_x64_20G_alibase_20240923.vhd"
  instance_type        = "ecs.g7.large"
  security_groups      = [alicloud_security_group.dev-sg[count.index].id]
  vswitch_id           = module.vpc.vswitch_ids[1]
  password             = "dynamic_random_password"
  system_disk_category = "cloud_essd"
  system_disk_size     = 100
  tags = {
    Name = "${var.env_name}-${var.project}-dev-test"
  }

}