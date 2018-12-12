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
#   OR
# USAGE: deploy.sh --ecs_cluster=cluster_name --ecs_service=service_name [--image_name=image_name] [--image_version=image_version] [--aws_account_id=aws_account_id] [--aws_region=aws_region]
#

source $(dirname $0)/common.sh || echo "$0: Failed to source common.sh"
processCliArgs $@

test -z ${ARGS[--ecs_cluster]} && ARGS[--ecs_cluster]=$1
test -z ${ARGS[--ecs_service]} && ARGS[--ecs_service]=$2
test -z ${ARGS[--image_name]} && ARGS[--image_name]=${3:-${CIRCLE_PROJECT_REPONAME}}
test -z ${ARGS[--image_version]} && ARGS[--image_version]=${4:-${CIRCLE_BUILD_NUM}}
test -z ${ARGS[--aws_account_id]} && ARGS[--aws_account_id]=${5:-"307921801440"}
test -z ${ARGS[--aws_region]} && ARGS[--aws_region]=${6:-"eu-west-1"}

deploy() {
    if [[ $(aws ecs update-service --cluster ${ARGS[--ecs_cluster]} --service ${ARGS[--ecs_service]} --task-definition $revision \
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

	task_def=$(printf "$task_template" ${ARGS[--ecs_service]} ${ARGS[--aws_account_id]} ${ARGS[--aws_region]} ${ARGS[--image_name]} ${ARGS[--image_version]})
}

register_task_definition() {
    echo "Registering task definition ${task_def}"
    if revision=$(aws ecs register-task-definition --container-definitions "$task_def" --family "${ARGS[--ecs_service]}" --output text --query 'taskDefinition.taskDefinitionArn'); then
        echo "Revision: $revision"
    else
        echo "Failed to register task definition"
        return 1
    fi

}
#printCliArgs
#exit 0
make_task_definition
register_task_definition
deploy
