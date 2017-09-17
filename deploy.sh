#!/bin/bash

# Gets the current directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Create Application Load Balancer for the service 
terraform apply

# Apply LB variables exported by terraform
source $SCRIPT_DIR/.pipelines/export_env_vars.sh

# Creates containers based on docker-compose.yml file
ecs-cli compose service up \
    --target-group-arn $ALB_TARGET_GROUP \
    --role $ALB_ROLE \
    --container-name $ECS_ENTRY_CONTAINER \
    --container-port $ECS_ENTRY_PORT \
    --cluster $ECS_CLUSTER_NAME
