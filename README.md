# **Spark on Kubernetes: A deep dive into scheduling, scaling and costs**

- [**Spark on Kubernetes: A deep dive into scheduling, scaling and costs**](#spark-on-kubernetes-a-deep-dive-into-scheduling-scaling-and-costs)
  - [**Overview**](#overview)
  - [**Resources**](#resources)
  - [**Architecture - High Level**](#architecture---high-level)
  - [**Details of components**](#details-of-components)
  - [**Advanced Scheduling with Yunikorn**](#advanced-scheduling-with-yunikorn)
    - [**Challenges**](#challenges)
    - [**Gang scheduling**](#gang-scheduling)
    - [**How to work Spark-operator with Yunikorn and Cluster autoscaler**](#how-to-work-spark-operator-with-yunikorn-and-cluster-autoscaler)
    - [**Configurating Spark-Operator wth Yunikorn**](#configurating-spark-operator-wth-yunikorn)
    - [**Configurating spark workloads**](#configurating-spark-workloads)
    - [**Configurating Yunikorn queues**](#configurating-yunikorn-queues)
  - [**Scaling strategy**](#scaling-strategy)
    - [**Core components**](#core-components)
    - [**Spark drivers and executors**](#spark-drivers-and-executors)
    - [](#)
  - [**Cost-effective strategy: On-demand and Spot**](#cost-effective-strategy-on-demand-and-spot)
  - [**How to work JupyterHub with Karpenter**](#how-to-work-jupyterhub-with-karpenter)
  - [**Deploying the solution**](#deploying-the-solution)
  - [**Testing the solution**](#testing-the-solution)
    - [**Requeriments**](#requeriments)
    - [**Spark jobs**](#spark-jobs)
    - [**JupyterHub Notebook**](#jupyterhub-notebook)

## **Overview**

The vast majority of corporations have Spark workloads for Batch processing, Near Real Time as well as user analytics environments. Many of these workloads are being migrated to cloud environments, both fully managed solutions from cloud providers and third-party solutions running on cloud infrastructure. The decision about which platform to choose is not always easy, each corporation has its needs and this article does not intend to answer this question.

Spark supports Kubernetes from version 2.3 (2018) and Production Ready/Generally Available from version 3.1 (2021). Among the many advantages of adopting a Spark approach over Kubernetes, we highlight the low-level management of the behavior of your workloads, regardless of the environment where they are executed, but this implies having advanced knowledge mainly about the scheduling and scaling components, with all that this entails (High Availability strategy, cost strategy, etc.).

In this article we are going to expose a solution on AWS that aims to build a Spark platform on EKS to support batch processes and analytical environments through notebooks.

## **Resources**

All the infrastructure and processes can be found in the following [GitHub](https://github.com/angelmaroco/spark-on-aws-eks-with-karpenter) repository ([MIT License](https://github.com/angelmaroco/spark-on-aws-eks-with-karpenter/blob/main/LICENSE))


## **Architecture - High Level**

The following image shows the high-level architecture on AWS with High Availability Multi-AZ and Single Region.

![](/docs/images/diagram-aws-architecture-high-level.png)

## **Details of components**

* **Kubernetes**:
  * Kubernetes EKS v1.23
* **Spark**:
  * Spark engine v3.2.0
  * Spark-operator v1.1.14
* **Scheduling**:
  * Yunikorn v1.1.0
* **Scaling**:
  * Cluster autoscaler v9.21.0
  * Karpenter v0.16.3
* **Analytics**:
  * JupyterHub v2.0.0
* **Infrastructure**:
  * aws-node-termination-handler v0.16.0
* **Policy and Governance**
  * Gatekeeper v3.10.0
* **Logging & Monitoring**:
  * Grafana v6.26.2
  * Prometheus v15.8.1
  * Spark History v4.1.0


## **Advanced Scheduling with Yunikorn**

### **Challenges**

Distributed processing with Spark on Kubernetes presents two challenges to solve: **improve resource utilization and Autoscaling performance**.

By default, when we execute a spark job, the kubernetes scheduler does not know the number of executors it will have to launch, regardless of the mechanism used to launch the job (spark-operator, spark-submit, etc). In the first instance, the driver will be started and then the executors, which has a direct impact on how the resources are allocated and how the cluster must scale with respect to the number of nodes.

For a better understanding of the problem, we are going to show a simplified version of the definition of a spark job with spark-operator. Our spark job has 1 driver and 2 executors defined:

```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
...
spec:
  driver:
    cores: 1
    coreRequest: "850m"
    memory: "2300m"
    memoryOverhead: "500m"
  executor:
    cores: 1
    instances: 2
    coreRequest: "850m"
    memory: "2400m"
    memoryOverhead: "500m"
```

In the following graph we see the behavior of the job using the default kubernetes scheduler.

![](/docs/images/yunikorn-without-gang.png)

### **Gang scheduling**

Now we are going to define a task group specifying the necessary resources for the creation of executors.

```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
...
spec:
  batchScheduler: "yunikorn"
  driver:
    cores: 1
    coreRequest: "850m"
    memory: "2300m"
    memoryOverhead: "500m"
    annotations:
      yunikorn.apache.org/schedulingPolicyParameters: "placeholderTimeoutSeconds=30"
      yunikorn.apache.org/task-group-name: "spark-driver-001"
      yunikorn.apache.org/task-groups: |-
        [{
          "name": "spark-driver-001",
          "minMember": 1,
          "minResource": {
            "cpu": "850m",
            "memory": "2800M"
          },
          "affinity": {
            ...
          }
        },
        {
          "name": "spark-executor-001",
          "minMember": 2,
          "minResource": {
            "cpu": "850m",
            "memory": "2800M"
          },
          "affinity": {
            ...
          }
        }]
  executor:
    cores: 1
    instances: 2
    coreRequest: "850m"
    memory: "2300m"
    memoryOverhead: "500m"
    annotations:
      yunikorn.apache.org/task-group-name: "spark-executor-001"
```

![](/docs/images/yunikorn-with-gang.png)


### **How to work Spark-operator with Yunikorn and Cluster autoscaler**

![](/docs/images/diagram-spark-operator-karpenter.png)

### **Configurating Spark-Operator wth Yunikorn**


The following code snippets can be seen [here](./scripts/templates/sparkapplication-testing-yunikorn.yaml)


```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: example-low-${UUID}
  namespace: spark-apps                 # Namespace where you will run the job.
  labels:
    app: spark-job-${UUID}              # App name
    applicationId: example-low-${UUID}  # App Id. This parameter should be unique, used to perform pod grouping
    queue: "root.spark-apps"            # Yunikorn queue.
```

```yaml
spec:
  batchScheduler: "yunikorn"            # Specified batch scheduler (If we don't specify this parameter, it will use kube-scheduler.)
```

```yaml
  driver:
    cores: 1
    coreRequest: "850m"
    memory: "2300m"
    memoryOverhead: "500m"
    annotations:
      yunikorn.apache.org/schedulingPolicyParameters: "placeholderTimeoutSeconds=30"
      yunikorn.apache.org/task-group-name: "spark-driver-${UUID}"
      yunikorn.apache.org/task-groups: |-
        [
          {
            "name": "spark-driver-${UUID}",
            "minMember": 1,
            "minResource": {
              "cpu": "850m",
              "memory": "3000M"
            },
            "affinity": {
              "nodeAffinity": {
                "requiredDuringSchedulingIgnoredDuringExecution": {
                  "nodeSelectorTerms": [
                    {
                      "matchExpressions": [
                        {
                          "key": "workload",
                          "operator": "In",
                          "values": [
                            "${TYPE_WORKLOAD}-driver"
                          ]
                        }
                      ],
                      "topologyKey": "topology.kubernetes.io/zone"
                    }
                  ]
                }
              }
            }
          },
          {
            "name": "spark-executor-${UUID}",
            "minMember": 2,
            "minResource": {
              "cpu": "850m",
              "memory": "3000M"
            },
            "affinity": {
              "nodeAffinity": {
                "requiredDuringSchedulingIgnoredDuringExecution": {
                  "nodeSelectorTerms": [
                    {
                      "matchExpressions": [
                        {
                          "key": "workload",
                          "operator": "In",
                          "values": [
                            "${TYPE_WORKLOAD}-executor"
                          ]
                        }
                      ],
                      "topologyKey": "topology.kubernetes.io/zone"
                    }
                  ]
                }
              },
              "podAffinity": {
                "requiredDuringSchedulingIgnoredDuringExecution": [
                  {
                    "labelSelector": {
                      "matchExpressions": [
                        {
                          "key": "applicationId",
                          "operator": "In",
                          "values": [
                            "example-low-${UUID}"
                          ]
                        }
                      ]
                    },
                    "topologyKey": "topology.kubernetes.io/zone"
                  }
                ]
              }
            }
          }
        ]
  ```

  ```yaml
  executor:
    cores: 1
    instances: 2
    coreRequest: "850m"
    memory: "2400m"
    memoryOverhead: "500m"
    labels:
      version: 3.2.0
    volumeMounts:
      - name: "spark-volume-testing-${UUID}"
        mountPath: "/tmp"
    annotations:
      yunikorn.apache.org/task-group-name: "spark-executor-${UUID}"

```

[definition](./terraform/templates/yunikorn_scheduler.yaml)

```yaml
operatorPlugins: "general,spark-k8s-operator"
```

### **Configurating spark workloads**

### **Configurating Yunikorn queues**

[definition](./terraform/templates/yunikorn_scheduler.yaml)

![](/docs/images/yunikorn-front-queues.png)

```yaml
configuration: |
  partitions:
    - name: default
      placementrules:
        - name: tag
          value: namespace
          create: true
      queues:
        - name: root
          submitacl: '*'
          properties:
            application.sort.policy: fifo
          queues:
            - name: spark-apps
              resources:
                guaranteed:
                  memory: 300G
                  vcore: 100
                max:
                  memory: 3000G
                  vcore: 1000
```

[More info about queues config](https://yunikorn.apache.org/docs/user_guide/queue_config)

## **Scaling strategy**

### **Core components**

### **Spark drivers and executors**


spark.kubernetes.node.selector.topology.kubernetes.io/zone='<availability zone>'

```yaml
  locals {

    private_subnet_az1_id   = [module.aws_baseline_vpc.private_subnets[0]]
    private_subnet_az1_name = "az1"

    private_subnet_az2_id   = [module.aws_baseline_vpc.private_subnets[1]]
    private_subnet_az2_name = "az2"

    private_subnet_az3_id   = [module.aws_baseline_vpc.private_subnets[2]]
    private_subnet_az3_name = "az3"
  ...
  }

  worker_groups_launch_template = [
    {
      name                          = "${var.aws_baseline_eks.worker_groups_spark_driver_low_cpu_name}-${local.private_subnet_az1_name}"
      subnets                       = local.private_subnet_az1_id
      ...
    },
    {
      name                          = "${var.aws_baseline_eks.worker_groups_spark_executor_low_cpu_name}-${local.private_subnet_az1_name}"
      subnets                       = local.private_subnet_az1_id
      ...
    },

    {
      name                          = "${var.aws_baseline_eks.worker_groups_spark_driver_low_cpu_name}-${local.private_subnet_az2_name}"
      subnets                       = local.private_subnet_az2_id
      ...
    },
    {
      name                          = "${var.aws_baseline_eks.worker_groups_spark_executor_low_cpu_name}-${local.private_subnet_az2_name}"
      subnets                       = local.private_subnet_az2_id
      ...
    },

    {
      name                          = "${var.aws_baseline_eks.worker_groups_spark_driver_low_cpu_name}-${local.private_subnet_az3_name}"
      subnets                       = local.private_subnet_az3_id
      ...
      ...
    },
    {
      name                          = "${var.aws_baseline_eks.worker_groups_spark_executor_low_cpu_name}-${local.private_subnet_az3_name}"
      subnets                       = local.private_subnet_az3_id
      ...
    }

  ]
```


```yaml
extraArgs:
  expander: priority
  balance-similar-node-groups: false

expanderPriorities: |-
  50:
    - .*az3.*
  60:
    - .*az2.*
  70:
    - .*az1.*
```

###

## **Cost-effective strategy: On-demand and Spot**







## **How to work JupyterHub with Karpenter**

![](/docs/images/diagram-jupyterhub-karpenter.png)


## **Deploying the solution**

With the following command we will create all the infrastructure and push the images used by the spark processes over ECR (spark jobs and jupyterhub notebooks).

```bash
cd terraform
terraform apply
```

## **Testing the solution**

### **Requeriments**

Setup k8s context

```bash
# Setup environment
bash scripts/setup-eks-client-environment.sh -r <aws-region>

# Example
./scripts/setup-eks-client-environment.sh -r eu-west-1
```

### **Spark jobs**
```bash
# Launch 2 spark job of type workload-low-cpu
bash scripts/launch-massive-jobs.sh  -a <aws-account> -r <aws-region> -n <num-jobs> -t workload-low-cpu
bash scripts/launch-massive-jobs.sh  -a <aws-account> -r <aws-region> -n <num-jobs> -t workload-high-cpu

# Examples
bash scripts/launch-massive-jobs.sh  -a 123456789012 -r eu-west-1 -n 2 -t workload-low-cpu
bash scripts/launch-massive-jobs.sh  -a 123456789012 -r eu-west-1 -n 2 -t workload-high-cpu
```


### **JupyterHub Notebook**
