#!/bin/bash

############################################################
# Build spark image and push to ECR                        #
############################################################

usage() { echo "Usage: $0 -a <AWS_ACCOUNT (123456789012)> -r <AWS_REGION (eu-west-1)>" 1>&2; exit 1; }

while getopts a:r: flag
do
    case "${flag}" in
        a) AWS_ACCOUNT=${OPTARG};;
        r) AWS_REGION=${OPTARG};;
        *) usage;;
    esac
done

if [ -z "${AWS_ACCOUNT}" ] || [ -z "${AWS_REGION}" ]; then
    usage
fi

AWS_ECR_URI="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"

IMAGE_SOURCE="angelmaroco/spark:3.2.0-hadoop-3.2-aws-sdk-1.12.132-python-3.8"

IMAGE_TARGET_TAG="3.2.0"
ECR_REPOSITORY="spark-custom"
IMAGE_TARGET="${AWS_ECR_URI}/${ECR_REPOSITORY}:${IMAGE_TARGET_TAG}"

echo "** Checking AWS ECR repository ${ECR_REPOSITORY}..."
aws ecr describe-repositories --repository-names "${ECR_REPOSITORY}" 2>&1 > /dev/null
if [[ ! "$?" -eq 0 ]]; then
    exit
fi

echo "** Logging AWS ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ECR_URI} 2>&1 > /dev/null

echo "** Downloading image..."
docker pull ${IMAGE_SOURCE}

echo "** Tagging local image..."
docker tag ${IMAGE_SOURCE} ${IMAGE_TARGET}

echo "** Pushing image to ECR"
docker push ${IMAGE_TARGET}
