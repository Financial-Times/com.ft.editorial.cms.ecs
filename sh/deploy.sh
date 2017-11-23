#!/usr/bin/env bash
#
# Create ECS task defintion and update service
#
# Script is intended to be run by CircleCI. It references variables CIRCLE_PROJECT_REPONAME and  CIRCLE_BUILD_NUM
# unless passed in as command line parameter
#
# Script is based on https://github.com/circleci/go-ecs-ecr/blob/master/deploy.sh
#
# USAGE: deploy.sh <ecs_cluster> <ecs_service> [image_name] [image_version] [aws_account_id] [region]
#

CLUSTER=$1
SERVICE=$2
IMAGE_NAME=${3:-${CIRCLE_PROJECT_REPONAME}}
IMAGE_VERSION=${4:-${CIRCLE_BUILD_NUM}}
AWS_ACCOUNT_ID=${5:-"307921801440"}
REGION=${6:-"eu-west-1"}

deploy() {
    if [[ $(aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE} --task-definition $revision \
            --output text --query 'service.taskDefinition') != $revision ]]; then
        echo "Error updating service."
        return 1
    fi
}

make_task_definition(){
	task_template='[
		{
			"name": "%s",
			"image": "%s.dkr.ecr.%s.amazonaws.com/%s:%s",
			"essential": true,
			"memory": 256,
			"cpu": 10,
			"portMappings": [
				{
					"containerPort": 80
				}
			]
		}
	]'

	task_def=$(printf "$task_template" ${SERVICE} ${AWS_ACCOUNT_ID} ${REGION} ${IMAGE_NAME} ${IMAGE_VERSION})
}

register_task_definition() {
    echo "Registering task definition ${task_def}"
    if revision=$(aws ecs register-task-definition --container-definitions "$task_def" --family "${SERVICE}" --output text --query 'taskDefinition.taskDefinitionArn'); then
        echo "Revision: $revision"
    else
        echo "Failed to register task definition"
        return 1
    fi

}

make_task_definition
register_task_definition
deploy
