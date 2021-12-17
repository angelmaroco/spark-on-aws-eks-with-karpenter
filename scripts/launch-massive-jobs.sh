#!/bin/bash

NUM_JOBS=2
PATH_TEMPLATE="templates"
FILE_TEMPLATE="spark-job-high-priority-template.yaml"
TEMP_TEMPLATE="/tmp"

for (( i=1; i<=${NUM_JOBS}; i++ )); do
    export UUID="sec${i}-$(cat /proc/sys/kernel/random/uuid)"
    envsubst < ${PATH_TEMPLATE}/${FILE_TEMPLATE} > ${TEMP_TEMPLATE}/${FILE_TEMPLATE}.${UUID}

    kubectl apply -f ${TEMP_TEMPLATE}/${FILE_TEMPLATE}.${UUID} &
done

while true
do
    for n in $(kubectl get nodes -l karpenter.sh/capacity-type=spot --no-headers | cut -d " " -f1); do
        echo "Pods on instance ${n}:";
        kubectl get pods -n default --no-headers --field-selector spec.nodeName=${n} ; echo ;
    done
 sleep 5
done
