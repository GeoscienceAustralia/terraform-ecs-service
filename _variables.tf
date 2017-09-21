variable "aws_region" {
  description = "The region that the ecs is running in"
  default = "ap-southeast-2"
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
