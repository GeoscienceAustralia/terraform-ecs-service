# Terraform ECS Service

This is an example that can be used to deploy a web accessible service to an existing ECS cluster.

## Task Based Permissions

Task based permissions can be altered by changing [container_perms data object](/modules/ecs_polic_instance_policy.tf).
These are permissions specific to each container instance.

## Usage

Modify `docker-compose.yml` and `terraform.tfvars` to suit your needs. 

deploy by running `deploy.sh`
