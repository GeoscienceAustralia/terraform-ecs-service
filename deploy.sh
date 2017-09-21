#!/bin/bash


# Create Application Load Balancer for the service
terraform apply

# Apply LB variables exported by terraform
. .pipelines/export_env_vars.sh

# Creates containers based on docker-compose.yml file
# Note that after service creation the load balancer name, container name and port are considered immutable
# for that service definition
# http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html#load-balancing-concepts
ecs-cli compose \
    --task-role-arn $ECS_TASK_ROLE \
    service up \
    --target-group-arn $ALB_TARGET_GROUP \
    --role $ALB_ROLE \
    --container-name $ECS_ENTRY_CONTAINER \
    --container-port $ECS_ENTRY_PORT \
    --cluster $ECS_CLUSTER
