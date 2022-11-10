# Building Spark Data Platform on Kubernetes EKS

- [Building Spark Data Platform on Kubernetes EKS](#building-spark-data-platform-on-kubernetes-eks)
  - [Introduction](#introduction)
  - [Components](#components)
  - [Architecture - High Level](#architecture---high-level)
  - [Detail of infrastructure](#detail-of-infrastructure)
  - [Scheduling](#scheduling)
    - [How to work Yunikon Gang Scheduling](#how-to-work-yunikon-gang-scheduling)
  - [Scaling pods: cluster autoscaler vs Karpenter](#scaling-pods-cluster-autoscaler-vs-karpenter)
  - [How to work Spark-operator with Yunikorn and Cluster autoscaler](#how-to-work-spark-operator-with-yunikorn-and-cluster-autoscaler)
    - [Configurating spark workloads](#configurating-spark-workloads)
    - [Configurating quotes](#configurating-quotes)
  - [How to work JupyterHub with Karpenter](#how-to-work-jupyterhub-with-karpenter)
  - [Testing the solution](#testing-the-solution)
  - [Monitoring the solution](#monitoring-the-solution)
  - [Challenges Spark on Kubernetes](#challenges-spark-on-kubernetes)

## Introduction

## Components

* Kubernetes EKS v1.23
* Spark v3.2.0
* Yunikorn v1.1.0
* JupyterHub v2.0.0
* Grafana v6.26.2
* Prometheus v15.8.1
* Spark-operator v1.1.14
* Spark History v4.1.0
* Cluster autoscaler v9.21.0
* Karpenter v0.16.3
* aws-node-termination-handler v0.16.0

## Architecture - High Level

![](/docs/images/diagram-aws-architecture-high-level.png)


## Detail of infrastructure

## Scheduling

### How to work Yunikon Gang Scheduling

## Scaling pods: cluster autoscaler vs Karpenter

## How to work Spark-operator with Yunikorn and Cluster autoscaler

![](/docs/images/diagram-spark-operator-karpenter.png)



### Configurating spark workloads

### Configurating quotes

## How to work JupyterHub with Karpenter

![](/docs/images/diagram-jupyterhub-karpenter.png)


## Testing the solution


## Monitoring the solution


## Challenges Spark on Kubernetes
