# Building Spark Data Platform on Kubernetes EKS

- [Building Spark Data Platform on Kubernetes EKS](#building-spark-data-platform-on-kubernetes-eks)
  - [Introduction](#introduction)
  - [Components](#components)
  - [Architecture - High Level](#architecture---high-level)
  - [Detail of infrastructure](#detail-of-infrastructure)
  - [How to work Spark-operator with Yunikorn and Cluster autoscaler](#how-to-work-spark-operator-with-yunikorn-and-cluster-autoscaler)
    - [How to work Yunikon Gang Scheduling](#how-to-work-yunikon-gang-scheduling)
    - [Configurating spark workloads](#configurating-spark-workloads)
    - [Configurating quotes](#configurating-quotes)
  - [How to work JupyterHub with spark-operator and Karpenter](#how-to-work-jupyterhub-with-spark-operator-and-karpenter)
  - [Scaling pods: cluster autoscaler vs Karpenter](#scaling-pods-cluster-autoscaler-vs-karpenter)
  - [Testing the solution](#testing-the-solution)
  - [Monitoring the solution](#monitoring-the-solution)
  - [Challenges Spark on Kubernetes](#challenges-spark-on-kubernetes)

## Introduction

## Components

* Kubernetes EKS v1.23
* Spark v3.2.0
* Yunikorn v0.12.2
* JupyterHub v1.2.0
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


## How to work Spark-operator with Yunikorn and Cluster autoscaler

![](/docs/images/diagram-spark-operator-karpenter.png)

### How to work Yunikon Gang Scheduling

### Configurating spark workloads

### Configurating quotes

## How to work JupyterHub with spark-operator and Karpenter


## Scaling pods: cluster autoscaler vs Karpenter


## Testing the solution


## Monitoring the solution


## Challenges Spark on Kubernetes
