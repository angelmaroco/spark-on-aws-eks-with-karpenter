#!/bin/bash

############################################################
# Build spark image and push to ECR                        #
############################################################

usage() { echo "Usage: $0 -a <AWS_ACCOUNT (123456789012)> -r <AWS_REGION (eu-west-1)> -b <AWS_S3_BUCKET_SPARK_UI ()> -n <NUM_SPARK_JOBS (10)>" 1>&2; exit 1; }

while getopts a:r:b:n: flag
do
    case "${flag}" in
        a) AWS_ACCOUNT=${OPTARG};;
        r) AWS_REGION=${OPTARG};;
        b) AWS_S3_BUCKET_SPARK_UI=${OPTARG};;
        n) NUM_SPARK_JOBS=${OPTARG};;
        *) usage;;
    esac
done

if [ -z "${AWS_ACCOUNT}" ] || [ -z "${AWS_REGION}" ] || [ -z "${AWS_S3_BUCKET_SPARK_UI}" ] || [ -z "${NUM_SPARK_JOBS}" ]; then
    usage
fi

# Export environment variables
export AWS_ACCOUNT=${AWS_ACCOUNT}
export AWS_REGION=${AWS_REGION}
export AWS_S3_BUCKET_SPARK_UI=${AWS_S3_BUCKET_SPARK_UI}
export NUM_SPARK_JOBS=${NUM_SPARK_JOBS}

PATH_TEMPLATE="templates"
FILE_TEMPLATE="sparkapplication-default-template.yaml"
TEMP_TEMPLATE="/tmp"

for (( i=1; i<=${NUM_SPARK_JOBS}; i++ )); do
    export UUID="sec${i}-$(cat /proc/sys/kernel/random/uuid)"

    envsubst < ${PATH_TEMPLATE}/${FILE_TEMPLATE} > ${TEMP_TEMPLATE}/${FILE_TEMPLATE}.${UUID}

    kubectl apply -f ${TEMP_TEMPLATE}/${FILE_TEMPLATE}.${UUID} &
done
