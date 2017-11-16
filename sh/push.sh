#!/usr/bin/env bash
#
# Push Docker image to ECR
#
# Script is intended to be run by CircleCI. It references variables CIRCLE_PROJECT_REPONAME and  IMAGE_VERSION
# unless passed in as command line parameter
#
#
# USAGE: ./push.sh [image_name] [image_version] [aws_account_id] [region]

IMAGE_NAME=${1:-${CIRCLE_PROJECT_REPONAME}
IMAGE_VERSION=${2:-${CIRCLE_BUILD_NUM}}
AWS_ACCOUNT_ID=${3:-"307921801440"}
REGION=${4:-"eu-west-1"}

install_aws_cli() {
  echo "Update pip & awscli"
  pip install --upgrade pip
  pip install --upgrade awscli
}

# Check whether to install aws clis
which aws >/dev/null || install_aws_cli

echo "Set AWS region"
aws configure set default.region ${AWS_REGION}


echo "Login to ECR"
$(aws ecr get-login --no-include-email)

echo "Verify repository exists"
aws ecr describe-repositories --repository-names ${IMAGE_NAME} >/dev/null || \
aws ecr create-repository --repository-name ${IMAGE_NAME}}

echo "Tag image"
docker tag ${IMAGE_NAME}:${IMAGE_VERSION} \
  ${ECR_ENDPOINT}/${IMAGE_NAME}:${IMAGE_VERSION}
docker tag ${ECR_ENDPOINT}/${IMAGE_NAME}:${IMAGE_VERSION} \
  ${ECR_ENDPOINT}/${IMAGE_NAME}:latest

echo "Pushing container to ECR"
docker push ${ECR_ENDPOINT}/${IMAGE_NAME}
