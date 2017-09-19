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
  description = "The name of the service"
}

variable "container_name" {
  description = "The name of the container"
}

variable "container_port" {
  description = "the port of the container"
}

variable "cluster" {
  description = "The name of the ecs cluster"
}

variable "owner" {
  description = "The mailing list for who owns the service"
}

variable "environment" {
  description = "The name of the enviornment"
}

data "aws_vpc" "default" {
  tags {
    Name        = "${var.cluster}"
    Environment = "${var.environment}"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.default.id}"

  tags {
    Tier = "Public"
  }
}

module "ecs_policy" {
  source = "modules/ecs_policy"

  container_port        = "${var.container_port}"
  alb_security_group_id = "${module.public_layer.alb_security_group_id}"
  environment           = "${var.environment}"
  cluster               = "${var.cluster}"
  owner                 = "${var.owner}"
}

module "public_layer" {
  source = "modules/public_layer"

  environment       = "${var.environment}"
  cluster           = "${var.cluster}"
  service_name      = "${var.service_name}"
  alb_name          = "${var.environment}-${var.service_name}"
  vpc_id            = "${data.aws_vpc.default.id}"
  public_subnet_ids = "${data.aws_subnet_ids.public.ids}"
  container_port    = "${var.container_port}"
  owner             = "${var.owner}"
}

output "alb_target_group" {
  value = "${module.public_layer.default_alb_target_group}"
}

output "alb_dns_name" {
  value = "${module.public_layer.alb_dns_name}"
}

resource "null_resource" "alb_target_group" {
  triggers {
    trigger = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<CMD
echo "\
export ALB_TARGET_GROUP=${module.public_layer.default_alb_target_group}
export ALB_ROLE=/ecs/${var.environment}_ecs_lb_role
export ECS_TASK_ROLE=${module.ecs_policy.access_to_ssm_role_arn}
export ECS_ENTRY_CONTAINER=${var.container_name}
export ECS_ENTRY_PORT=${var.container_port}
export ECS_CLUSTER=${var.cluster}\
" > ./.pipelines/export_env_vars.sh
CMD
  }
}
