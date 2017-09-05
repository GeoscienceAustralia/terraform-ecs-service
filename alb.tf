terraform {
  required_version = ">= 0.10.0"

  backend "s3" {
    bucket = "dea-devs-tfstate"

    key = "ecs-test-service/"

    region = "ap-southeast-2"

    dynamodb_table = "terraform"
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

variable "service_name" {
  description   = "The name of the service"
}

variable "container_name" {
  description   = "The name of the container"
}

variable "container_port" {
  description   = "the port of the container"
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
  container_port    = "${var.container_port}"
}

# Add permissions to ECS instances to access ALB
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = "${var.container_port}"
  to_port                  = "${var.container_port}"
  protocol                 = "TCP"
  source_security_group_id = "${module.alb.alb_security_group_id}"
  security_group_id        = "${data.aws_security_group.ecs_instance_security_group.id}"
}

output "alb_target_group" {
  value       = "${module.alb.default_alb_target_group}"
}

output "alb_dns_name" {
  value       = "${module.alb.alb_dns_name}"
}

resource "null_resource" "alb_target_group" {
  triggers {
    trigger = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<CMD
echo "\
export ALB_TARGET_GROUP=${module.alb.default_alb_target_group} 
export ALB_ROLE=/ecs/acc_ecs_lb_role
export ECS_ENTRY_CONTAINER=${var.container_name}
export ECS_ENTRY_PORT=${var.container_port}\
" > ./.pipelines/export_env_vars.sh
CMD
  }
}
