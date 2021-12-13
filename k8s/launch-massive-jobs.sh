#!/bin/bash

NUM_JOBS=5
PATH_TEMPLATE="templates"
FILE_TEMPLATE="spark-job-high-priority-template.yaml"
TEMP_TEMPLATE="/tmp"

for (( i=1; i<=${NUM_JOBS}; i++ )); do
    export UUID="sec${i}-$(cat /proc/sys/kernel/random/uuid)"
    envsubst < ${PATH_TEMPLATE}/${FILE_TEMPLATE} > ${TEMP_TEMPLATE}/${FILE_TEMPLATE}.${UUID}
    
    kubectl apply -f ${TEMP_TEMPLATE}/${FILE_TEMPLATE}.${UUID} &
done
