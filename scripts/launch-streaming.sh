#!/bin/bash

############################################################
# Launch spark job                                         #
############################################################

usage() { echo "Usage: $0 -a <AWS_ACCOUNT (123456789012)> -r <AWS_REGION (eu-west-1)> -n <NUM_SPARK_JOBS (10)> -t <TYPE_WORKLOAD (workload-intensive-cpu|workload-moderate-cpu|workload-low-cpu|workload-intensive-memory)" 1>&2; exit 1; }

while getopts a:r:n:t: flag
do
    case "${flag}" in
        a) AWS_ACCOUNT=${OPTARG};;
        r) AWS_REGION=${OPTARG};;
        n) NUM_SPARK_JOBS=${OPTARG};;
        t) TYPE_WORKLOAD=${OPTARG};;
        *) usage;;
    esac
done

if [ -z "${AWS_ACCOUNT}" ] || [ -z "${AWS_REGION}" ] || [ -z "${NUM_SPARK_JOBS}" ] || [ -z "${TYPE_WORKLOAD}" ]; then
    usage
fi

# Export environment variables
export AWS_ACCOUNT=${AWS_ACCOUNT}
export AWS_REGION=${AWS_REGION}
export AWS_S3_BUCKET_SPARK_UI="${AWS_REGION}-${AWS_ACCOUNT}-spark-on-aws-eks"
export NUM_SPARK_JOBS=${NUM_SPARK_JOBS}
export TYPE_WORKLOAD=${TYPE_WORKLOAD}

PATH_TEMPLATE="scripts/templates"
FILE_TEMPLATE="sparkapplication-testing-streaming.yaml"

for (( i=1; i<=${NUM_SPARK_JOBS}; i++ )); do
    export UUID="$(cat /proc/sys/kernel/random/uuid | cut -c 1-8)"

    cat ${PATH_TEMPLATE}/${FILE_TEMPLATE} | envsubst | kubectl apply -f - &
done
