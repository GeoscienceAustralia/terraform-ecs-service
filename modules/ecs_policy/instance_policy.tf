data "aws_iam_policy_document" "ecs_extra_perms" {

  statement {
    actions = [
      "ssm:GetParameters"
    ]

    resources = [
      "arn:aws:ssm:ap-southeast-2::538673716275:parameter*"
    ]
  }

  statement {
    actions = [
      "kms:*"
    ]

    resources = [
      "arn:aws:kms:ap-southeast-2:538673716275:key/efba9b4c-8e64-430c-86c9-f00eaf69e582"
    ]
  }
}


data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


resource "aws_iam_policy" "access_to_ssm" {
  name = "tf_access_to_ssm_exc"
  path = "/"
  policy = "${data.aws_iam_policy_document.ecs_extra_perms.json}"
}

resource "aws_iam_role" "instance_role" {
  name = "tf_odc_ecs_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
/*
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
*/
}

resource "aws_iam_policy_attachment" "ssm_perms_to_odc_role" {
  name = "attach_ssm_policy_to_odc_ecs"
  roles = ["${aws_iam_role.instance_role.name}"]
  policy_arn = "${aws_iam_policy.access_to_ssm.id}"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_role" {
  role = "${aws_iam_role.instance_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_cloudwatch_role" {
  role = "${aws_iam_role.instance_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
