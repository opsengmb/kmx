data "alicloud_alb_zones" "default" {}

resource "alicloud_alb_load_balancer" "alb" {
  vpc_id                 = module.vpc.vpc_id
  resource_group_id     = alicloud_resource_manager_resource_group.rg.id 
  address_type           = "Internet"
  address_allocated_mode = "Fixed"
  load_balancer_name     = "${var.env_name}-${var.project}-alb"
  load_balancer_edition  = "StandardWithWaf"
  load_balancer_billing_config {
    pay_type = "PayAsYouGo"
  }
  tags = {
    name = "${var.env_name}-${var.project}-intra-alb"
  }
  zone_mappings {
    vswitch_id = module.vpc.vswitch_ids[1]
    zone_id    = data.alicloud_alb_zones.default.zones.1.id
  }
   zone_mappings {
    vswitch_id = module.vpc.vswitch_ids[2]
    zone_id    = data.alicloud_alb_zones.default.zones.0.id
  }
  modification_protection_config {
    status = "NonProtection"
  }
}

// listener port 80
resource "alicloud_alb_listener" "http_80" {
  load_balancer_id     = alicloud_alb_load_balancer.alb.id
  listener_protocol    = "HTTP"
  listener_port        = 80
  listener_description = "${var.env_name}-${var.project}-80-listener"
  x_forwarded_for_config {
    x_forwarded_for_proto_enabled = true
    x_forwarded_for_enabled = true
  }
  default_actions {
    type = "ForwardGroup"
    forward_group_config {
      server_group_tuples {
        server_group_id = alicloud_alb_server_group.bo_be_grp.id
      }
    }
  }
}

/*
// listener port 443
resource "alicloud_alb_listener" "https_443" {
  load_balancer_id     = alicloud_alb_load_balancer.alb.id
  listener_protocol    = "HTTPS"
  listener_port        = 443
  listener_description = "${var.env_name}-${var.project}-443-listener"
  x_forwarded_for_config {
    x_forwarded_for_proto_enabled = true
    x_forwarded_for_enabled = true
  }
  default_actions {
    type = "ForwardGroup"
    forward_group_config {
      server_group_tuples {
       server_group_id = alicloud_alb_server_group.bo_be_grp.id
      }
    }
  }
  certificates {
    certificate_id = var.cert_id
  }
}

// THIS IS GL BE
resource "alicloud_alb_rule" "gl_be_rule_https" {
  rule_name   = "${var.env_name}-${var.project}-gl-be-rule-https"
  listener_id = alicloud_alb_listener.https_443.id
  priority    = "3"
  rule_conditions {
    type = "Host"
    host_config {
      values = ["${var.gl_be_domain}"]
    }
  }

  rule_actions {
    forward_group_config {
      server_group_tuples {
        server_group_id = alicloud_alb_server_group.gl_be_grp.id
      }
    }
    order = "1"
    type  = "ForwardGroup"
  }
}


resource "alicloud_alb_server_group" "bo_be_grp" {
  protocol          = "HTTP"
  vpc_id            = module.vpc.vpc_id
  server_group_name = "${var.env_name}-${var.project}-bo-be-grp"
  resource_group_id = alicloud_resource_manager_resource_group.rg.id 
  health_check_config {
    health_check_connect_port = "80"
    health_check_enabled      = true
    health_check_codes        = ["http_2xx", "http_3xx"]
    health_check_interval     = "2"
    health_check_protocol     = "TCP"
    health_check_timeout      = 5
    healthy_threshold         = 3
    unhealthy_threshold       = 3
  }
  sticky_session_config {
    sticky_session_enabled = false
    cookie                 = "tf-example"
    sticky_session_type    = "Server"
  }
  servers {
    description = "${var.env_name}-${var.project}-bo-be"
    port        = 80
    server_id   = alicloud_instance.bo_be_ecs_instance_1.id
    server_type = "Ecs"
  }
}

resource "alicloud_alb_rule" "gl_fe_rule_https" {
  count = var.env_name == "prod" ? 1 : 0
  rule_name   = "${var.env_name}-${var.project}-gl-fe-rule-https"
  listener_id = alicloud_alb_listener.https_443.id
  priority    = "2"
  rule_conditions {
    type = "Host"
    host_config {
      values = ["${var.gl_fe_domain}","${var.project}.ph"]
    }
  }

  rule_actions {
    forward_group_config {
      server_group_tuples {
        server_group_id = alicloud_alb_server_group.gl_fe_grp[count.index].id
      }
    }
    order = "1"
    type  = "ForwardGroup"
  }
}


resource "alicloud_alb_server_group" "gl_fe_grp" {
  count = var.env_name == "prod" ? 1 : 0
  protocol          = "HTTP"
  vpc_id            = module.vpc.vpc_id
  server_group_name = "${var.env_name}-${var.project}-gl-fe-grp"
  resource_group_id = alicloud_resource_manager_resource_group.rg.id 
  health_check_config {
    health_check_connect_port = "80"
    health_check_enabled      = true
    health_check_codes        = ["http_2xx", "http_3xx"]
    health_check_interval     = "2"
    health_check_protocol     = "TCP"
    health_check_timeout      = 5
    healthy_threshold         = 3
    unhealthy_threshold       = 3
  }
  sticky_session_config {
    sticky_session_enabled = false
    cookie                 = "tf-example"
    sticky_session_type    = "Server"
  }
  servers {
    description = "${var.env_name}-${var.project}-gl-fe"
    port        = 80
    server_id   = alicloud_instance.gl_fe_ecs_instance_1[count.index].id
    server_type = "Ecs"
  }
}

// THIS IS BO FE
resource "alicloud_alb_rule" "bo_fe_rule_https" {
  count = var.env_name == "prod" ? 1 : 0
  rule_name   = "${var.env_name}-${var.project}-bo-fe-rule-https"
  listener_id = alicloud_alb_listener.https_443.id
  priority    = "4"
  rule_conditions {
    type = "Host"
    host_config {
      values = ["${var.bo_fe_domain}"]
    }
  }

  rule_actions {
    forward_group_config {
      server_group_tuples {
        server_group_id = alicloud_alb_server_group.bo_fe_grp[count.index].id
      }
    }
    order = "1"
    type  = "ForwardGroup"
  }
}

resource "alicloud_alb_server_group" "bo_fe_grp" {
  count = var.env_name == "prod" ? 1 : 0
  protocol          = "HTTP"
  vpc_id            = module.vpc.vpc_id
  server_group_name = "${var.env_name}-${var.project}-bo-fe-grp"
  resource_group_id = alicloud_resource_manager_resource_group.rg.id 
  health_check_config {
    health_check_connect_port = "80"
    health_check_enabled      = true
    health_check_codes        = ["http_2xx", "http_3xx"]
    health_check_interval     = "2"
    health_check_protocol     = "TCP"
    health_check_timeout      = 5
    healthy_threshold         = 3
    unhealthy_threshold       = 3
  }
  sticky_session_config {
    sticky_session_enabled = false
    cookie                 = "tf-example"
    sticky_session_type    = "Server"
  }
  servers {
    description = "${var.env_name}-${var.project}-bo-fe"
    port        = 80
    server_id   = alicloud_instance.bo_fe_ecs_instance_1[count.index].id
    server_type = "Ecs"
  }
}

// THIS IS BO BE
resource "alicloud_alb_rule" "bo_be_rule_https" {
  count = var.env_name == "prod" ? 1 : 0
  rule_name   = "${var.env_name}-${var.project}-bo-be-rule-https"
  listener_id = alicloud_alb_listener.https_443.id
  priority    = "5"
  rule_conditions {
    type = "Host"
    host_config {
      values = ["${var.bo_be_domain}"]
    }
  }

  rule_actions {
    forward_group_config {
      server_group_tuples {
        server_group_id = alicloud_alb_server_group.bo_be_grp_true[count.index].id
      }
    }
    order = "1"
    type  = "ForwardGroup"
  }
}

resource "alicloud_alb_server_group" "bo_be_grp_true" {
  count = var.env_name == "prod" ? 1 : 0
  protocol          = "HTTP"
  vpc_id            = module.vpc.vpc_id
  server_group_name = "${var.env_name}-${var.project}-bo-be-grp"
  resource_group_id = alicloud_resource_manager_resource_group.rg.id 
  health_check_config {
    health_check_connect_port = "80"
    health_check_enabled      = true
    health_check_codes        = ["http_2xx", "http_3xx"]
    health_check_interval     = "2"
    health_check_protocol     = "TCP"
    health_check_timeout      = 5
    healthy_threshold         = 3
    unhealthy_threshold       = 3
  }
  sticky_session_config {
    sticky_session_enabled = false
    cookie                 = "tf-example"
    sticky_session_type    = "Server"
  }
  servers {
    description = "${var.env_name}-${var.project}-bo-be"
    port        = 80
    server_id   = alicloud_instance.gl_be_ecs_instance_1[count.index].id
    server_type = "Ecs"
  }
}
*/