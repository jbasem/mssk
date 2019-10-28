#!/usr/bin/env bash

##############
#### NOTE #### 
# Use this script to update an ECS service (defined by $ECS_CLUSTER_NAME and $ECS_SERVICE_NAME) with 
# the ECR image defined in the task defenition. (i.e. the LATEST), without updating the task revision.
##############


set -eo pipefail
# more bash-friendly output for jq
JQ="jq --raw-output --exit-status"

deploy_cluster() {
    ECS_CLUSTER_NAME=ms-app-dev
    ECS_SERVICE_NAME=ms-app-main-dev

    echo "Triggering ecs update-service"
    DEPLOYMENT_REVISION=$(aws ecs update-service \
      --cluster "${ECS_CLUSTER_NAME}" \
      --service "${ECS_SERVICE_NAME}" \
      --force-new-deployment \
      --output text \
      --query service.taskDefinition)
    if [ "$DEPLOYMENT_REVISION" = "" ]; then
        echo "Error updating service."
        return 1
    fi

    echo "Current revision: $DEPLOYMENT_REVISION"
    echo "Verifying service deployment.."
    attempt=0
    while [ "$attempt" -lt 20 ]
    do
        DEPLOYMENTS=$(aws ecs describe-services \
            --cluster ${ECS_CLUSTER_NAME} \
            --services ${ECS_SERVICE_NAME} \
            --output text \
            --query 'services[0].deployments[].[taskDefinition, status]')
        
        NUM_DEPLOYMENTS=$(aws ecs describe-services \
            --cluster ${ECS_CLUSTER_NAME} \
            --services ${ECS_SERVICE_NAME} \
            --output text \
            --query 'length(services[0].deployments)')

        READY_PRIMARY=$(aws ecs describe-services \
            --cluster ${ECS_CLUSTER_NAME} \
            --services ${ECS_SERVICE_NAME} \
            --output text \
            --query "services[0].deployments[?taskDefinition==\`$DEPLOYMENT_REVISION\` && runningCount == desiredCount && status == \`PRIMARY\`][taskDefinition]")

        echo "Current deployments: $DEPLOYMENTS"
        if [ "$NUM_DEPLOYMENTS" = "1" ] && [ "$READY_PRIMARY" = "$DEPLOYMENT_REVISION" ]; then
            echo "The task definition revision $DEPLOYMENT_REVISION is the only deployment for the service and has attained the desired running task count."
            echo "Deployment Succeeded!!"
            return 0
        else
            echo "Waiting for revision $DEPLOYMENT_REVISION to be primary with desired running count / older revisions to be stopped.."
            sleep 15
        fi
        attempt=$((attempt + 1))
    done
    echo "TIMEOUT: Stopped waiting for deployment to be stable - please check the status of deployment status on the AWS ECS console."
    return 1 
}

deploy_cluster
