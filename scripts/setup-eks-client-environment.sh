#!/bin/bash

usage() { echo "Usage: $0 -r <AWS_REGION (eu-west-1)>" 1>&2; exit 1; }

while getopts r: flag
do
    case "${flag}" in
        r) AWS_REGION=${OPTARG};;
        *) usage;;
    esac
done

EKS_CLUSTER="cluster-spark-on-aws-eks-dev"

# Setup kubeconfig and generate token
aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${AWS_REGION}
aws eks get-token --cluster-name ${EKS_CLUSTER}

# Apply Karpenter configuration
kubectl apply -f terraform/templates/karpenter_provisioners_low_cpu.yaml
kubectl apply -f terraform/templates/karpenter_provisioners_moderate_cpu.yaml
kubectl apply -f terraform/templates/karpenter_provisioners_intensive_cpu.yaml
kubectl apply -f terraform/templates/karpenter_provisioners_intensive_memory.yaml

# Port forwarding
kubectl port-forward service/grafana 3000:80 -n monitoring &
kubectl port-forward service/kubernetes-dashboard 3001:443 -n monitoring &
kubectl port-forward service/spark-history-server 3002:18080 -n monitoring &
kubectl port-forward service/proxy-public 3003:80 -n jupyterhub &

# Open browser
xdg-open http://localhost:3000
xdg-open https://localhost:3001
xdg-open http://localhost:3002
xdg-open http://localhost:3003
