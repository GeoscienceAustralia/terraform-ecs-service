data "aws_iam_policy_document" "container_perms" {
  statement {
    actions = [
      "ssm:GetParameters",
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter*",
    ]
  }

  statement {
    actions = [
      "kms:*",
    ]

    resources = [
      "arn:aws:kms:${var.aws_region}:${var.account_id}:key/${var.ssm_decrypt_key}",
    ]
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_security_group" "ecs_instance_security_group" {
  tags {
    Name        = "ecs_instance_sg"
    Environment = "${var.environment}"
    Cluster     = "${var.cluster}"
  }
}

resource "aws_iam_policy" "access_to_ssm" {
  name   = "tf_access_to_ssm_exc"
  path   = "/"
  policy = "${data.aws_iam_policy_document.container_perms.json}"
}

resource "aws_iam_role" "instance_role" {
  name               = "tf_odc_ecs_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

resource "aws_iam_policy_attachment" "ssm_perms_to_odc_role" {
  name       = "attach_ssm_policy_to_odc_ecs"
  roles      = ["${aws_iam_role.instance_role.name}"]
  policy_arn = "${aws_iam_policy.access_to_ssm.id}"
}

# Add permissions to ECS instances to access ALB
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = "${var.container_port}"
  to_port                  = "${var.container_port}"
  protocol                 = "TCP"
  source_security_group_id = "${var.alb_security_group_id}"
  security_group_id        = "${data.aws_security_group.ecs_instance_security_group.id}"
}
