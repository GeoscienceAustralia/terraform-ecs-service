provider "aws" {
  region = "ap-southeast-2"
}

variable "service_name" {
  description   = "The name of the service"
}

variable "cluster" {
  description   = "The name of the ecs cluster"
}

variable "environment" {
  description   = "The name of the enviornment"
}

data "aws_vpc" "default" {
  tags {
    Name        = "${var.cluster}"
    Environment = "${var.environment}"
  }
}

data "aws_security_group" "ecs_instance_security_group" {
  tags {
    Environment = "${var.environment}"
    Cluster     = "${var.cluster}"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.default.id}"
  tags {
    Tier        = "Public"
  }
}

module "alb" {
  source = "alb"

  environment       = "${var.environment}"
  alb_name          = "${var.environment}-${var.cluster}-${var.service_name}"
  vpc_id            = "${data.aws_vpc.default.id}"
  public_subnet_ids = "${data.aws_subnet_ids.public.ids}"
}

# Add permissions to ECS instances to access ALB
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = "${module.alb.alb_security_group_id}"
  security_group_id        = "${data.aws_security_group.ecs_instance_security_group.id}"
}

output "alb_target_group" {
  value       = "${module.alb.default_alb_target_group}"
}
