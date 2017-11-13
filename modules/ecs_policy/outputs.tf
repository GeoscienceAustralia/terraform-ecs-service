output "access_to_ssm_role_arn" {
  value = "${aws_iam_role.instance_role.arn}"
}
