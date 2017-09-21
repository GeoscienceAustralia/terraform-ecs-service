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
  region = "${var.aws_region}"
}

data "aws_caller_identity" "current" {}

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

  aws_region = "${var.aws_region}"
  account_id = "${data.aws_caller_identity.current.account_id}"
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
