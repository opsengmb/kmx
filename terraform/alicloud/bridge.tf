// new provider with different region
provider "alicloud" {
  alias   = "bridge"
  region  = "ap-northeast-1"
}

data "alicloud_zones" "bridge_zones" {
  provider          = alicloud.bridge
  available_resource_creation = "VSwitch"
}


resource "alicloud_vpc" "bridge_vpc" {
  provider          = alicloud.bridge
  vpc_name   = "${var.env_name}-${var.project}-vpc"
  cidr_block = var.bridge_vpc_cidr
  resource_group_id = alicloud_resource_manager_resource_group.rg.id 
}

resource "alicloud_vswitch" "bridge_vswitch_a" {
  provider          = alicloud.bridge
  vswitch_name = "${var.env_name}-${var.project}-vswitch-a"
  vpc_id       = alicloud_vpc.bridge_vpc.id
  cidr_block   = var.bridge_pub_a
  zone_id      = data.alicloud_zones.bridge_zones.zones.0.id
}


resource "alicloud_nat_gateway" "bridge_int_nat_gw1" {
  provider          = alicloud.bridge
  vpc_id           = alicloud_vpc.bridge_vpc.id
  nat_gateway_name = "${var.env_name}-${var.project}-ingw1"
  payment_type     = "PayAsYouGo"
  vswitch_id       = alicloud_vswitch.bridge_vswitch_a.id
  nat_type         = "Enhanced"
}

resource "alicloud_eip_association" "bridge_int_nat_assoc1" {
  provider          = alicloud.bridge
  allocation_id = alicloud_eip_address.bridge_eip_addr_snat1.id
  instance_type = "Nat"
  instance_id   = alicloud_nat_gateway.bridge_int_nat_gw1.id
}

resource "alicloud_eip_address" "bridge_eip_addr_snat1" {
  provider          = alicloud.bridge
  address_name  = "${var.env_name}-${var.project}-eipaddr1"
  resource_group_id = alicloud_resource_manager_resource_group.rg.id 
}

resource "alicloud_snat_entry" "bridge_int_nat_snat1" {
  provider          = alicloud.bridge
  snat_table_id     = alicloud_nat_gateway.bridge_int_nat_gw1.snat_table_ids
  source_vswitch_id = alicloud_vswitch.bridge_vswitch_a.id
  snat_ip           = alicloud_eip_address.bridge_eip_addr_snat1.ip_address
}

// SGRP
resource "alicloud_security_group" "bridge-sg" {
  provider          = alicloud.bridge
  resource_group_id = alicloud_resource_manager_resource_group.rg.id
  name        = "${var.env_name}-${var.project}-bridge-sg"
  description = "${var.env_name}-${var.project} security group"
  vpc_id = alicloud_vpc.bridge_vpc.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "alicloud_security_group_rule" "bridge-http" {
  provider          = alicloud.bridge
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.bridge-sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bridge-https" {
  provider          = alicloud.bridge
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.bridge-sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bridge-http-egress" {
  provider          = alicloud.bridge
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.bridge-sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bridge-https-egress" {
  provider          = alicloud.bridge
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.bridge-sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bridge-udp-dns-egress" {
  provider          = alicloud.bridge
  type              = "egress"
  ip_protocol       = "udp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.bridge-sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bridge-tcp-dns-egress" {
  provider          = alicloud.bridge
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.bridge-sg.id
  cidr_ip           = "0.0.0.0/0"
}


resource "alicloud_instance" "bridge_ecs_instance_1" {
    provider             = alicloud.bridge
    resource_group_id    = alicloud_resource_manager_resource_group.rg.id 
    instance_name        = "${var.env_name}-${var.project}-bridge"
    image_id             = var.bridge_image_id
    instance_type        = "ecs.g7.large"
    security_groups      = [alicloud_security_group.bridge-sg.id]
    vswitch_id           = alicloud_vswitch.bridge_vswitch_a.id
    password             = "dynamic_random_password"
    system_disk_category = "cloud_essd"
    system_disk_size     = 100
    tags = {
        Name = "${var.env_name}-${var.project}-bridge"
    }
}

// define a public ip for bridge_ecs_instance_1
resource "alicloud_eip_address" "bridge_eip" {
    resource_group_id = alicloud_resource_manager_resource_group.rg.id
    provider = alicloud.bridge
    bandwidth = "100"
    internet_charge_type = "PayByTraffic"
}

// make sure bridge_ecs_instance_1 is public
resource "alicloud_eip_association" "bridge_eip_assoc" {
    provider    = alicloud.bridge
    instance_id = alicloud_instance.bridge_ecs_instance_1.id
    allocation_id = alicloud_eip_address.bridge_eip.id
}
