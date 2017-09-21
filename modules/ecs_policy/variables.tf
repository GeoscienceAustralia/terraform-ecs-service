variable "container_port" {
  description = "The port that the ecs communicates with the alb"
}

variable "alb_security_group_id" {
  description = "The security group of the alb"
}

variable "environment" {
  description = "The name of the environment"
}

variable "cluster" {
  description = "The name of the cluster"
}

variable "owner" {
  description = "mailing list that represents the owner of the service"
}

variable "ssm_decrypt_key" {
  description = "Alias for the ssm decrypt key to access secure ssm parameters"
  default = "aws/ssm"
}

variable "account_id" {
  description = "The account id for specifying arns"
}

variable "aws_region" {
  description = "The aws region for the service"
}
