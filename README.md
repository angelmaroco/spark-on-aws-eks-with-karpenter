# **Spark on Kubernetes: A deep dive into scheduling, scaling and costs**

- [**Spark on Kubernetes: A deep dive into scheduling, scaling and costs**](#spark-on-kubernetes-a-deep-dive-into-scheduling-scaling-and-costs)
  - [**Overview**](#overview)
  - [**Resources**](#resources)
  - [**Architecture - High Level**](#architecture---high-level)
  - [**Details of components**](#details-of-components)
  - [**Advanced Scheduling**](#advanced-scheduling)
    - [**Challenges**](#challenges)
    - [**Gang Scheduling and bin-packing with Yunikorn**](#gang-scheduling-and-bin-packing-with-yunikorn)
    - [**How to work Spark-operator with Yunikorn and Cluster autoscaler**](#how-to-work-spark-operator-with-yunikorn-and-cluster-autoscaler)
    - [**Configurating Spark-Operator wth Yunikorn**](#configurating-spark-operator-wth-yunikorn)
    - [**Configurating Yunikorn queues**](#configurating-yunikorn-queues)
  - [**Availability and Scalability strategy**](#availability-and-scalability-strategy)
    - [**Core components**](#core-components)
    - [**Spark drivers and executors**](#spark-drivers-and-executors)
    - [**About Isolate Spark applications**](#about-isolate-spark-applications)
  - [**Cost-effective strategy: On-demand and Spot**](#cost-effective-strategy-on-demand-and-spot)
  - [**How to work JupyterHub with Karpenter**](#how-to-work-jupyterhub-with-karpenter)
  - [**Deploying the solution**](#deploying-the-solution)
  - [**Testing the solution**](#testing-the-solution)
    - [**Requeriments**](#requeriments)
    - [**Spark jobs**](#spark-jobs)
    - [**JupyterHub Notebook**](#jupyterhub-notebook)
  - [**References**](#references)

## **Overview**

The vast majority of corporations have Spark workloads for Batch processing, Streaming as well as user analytics environments. Many of these workloads are being migrated to cloud environments, both fully managed solutions from cloud providers and third-party solutions running on cloud infrastructure. The decision about which platform to choose is not always easy, each corporation has its needs and this article does not intend to answer this question.

Spark supports Kubernetes from version 2.3 (2018) and Production Ready/Generally Available from version 3.1 (2021). Among the many advantages of adopting a Spark approach over Kubernetes, we highlight the low-level management of the behavior of your workloads, regardless of the environment where they are executed, but this implies having advanced knowledge mainly about the scheduling and scaling components, with all that this entails (High Availability strategy, cost strategy, etc.).

In this article we are going to expose a solution on AWS that aims to build a Spark platform on EKS to support batch/streaming processes and analytical environments through notebooks.

## **Resources**

All the infrastructure and processes can be found in the following [GitHub](https://github.com/angelmaroco/spark-on-aws-eks-with-karpenter) repository ([MIT License](https://github.com/angelmaroco/spark-on-aws-eks-with-karpenter/blob/main/LICENSE))


## **Architecture - High Level**

The following image shows the high-level architecture on AWS with High Availability Multi-AZ and Single Region.

![](/docs/images/diagram-aws-architecture-high-level.png)

## **Details of components**

* **Kubernetes**:
  * Kubernetes EKS v1.26
* **Spark**:
  * Spark engine v3.2.0
  * Spark-operator v1.1.14
* **Scheduling**:
  * Yunikorn v1.2.0
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


## **Advanced Scheduling**

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

In the following graph we see the behavior of the job using the default kubernetes scheduler. **This way of scheduling pods is totally inefficient** in terms of execution time and resource allocation. In concurrency scenarios it can cause only the driver to be created and not the executors, so the process would have to wait for available resources while the driver is occupying resources.

![](/docs/images/yunikorn-without-gang.png)

### **Gang Scheduling and bin-packing with Yunikorn**

In distributed computing terms, gang scheduling refers to schedule correlated tasks in an All or Nothing manner, all resources needed for the full execution of the process are computed at job start. This mechanism avoids the segmentation of resources and optimizes the execution time since all the nodes necessary for the execution are created or assigned initially.



Now we are going to define a task group specifying the necessary resources for the creation of drivers and executors.

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
                "preferredDuringSchedulingIgnoredDuringExecution": [
                  {
                    "weight": 100,
                    "podAffinityTerm": {
                      "labelSelector": {
                        "matchExpressions": [
                          {
                            "key": "applicationId",
                            "operator": "In",
                            "values": [
                              "example-spark-${UUID}"
                            ]
                          }
                        ]
                      },
                      "topologyKey": "topology.kubernetes.io/zone"
                    }
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
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: workload
              operator: In
              values:
              - "${TYPE_WORKLOAD}-executor"
      podAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: applicationId
                operator: In
                values:
                - example-spark-${UUID}
            topologyKey: topology.kubernetes.io/zone


```

[definition](./terraform/templates/yunikorn_scheduler.yaml)

```yaml
operatorPlugins: "general,spark-k8s-operator"
```

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

## **Availability and Scalability strategy**

At the time of designing the scaling strategy, many doubts arise, there is no single answer, everything will depend on the needs of the customer regarding the type of workloads to be executed and the availability of the platform. Depending on the type of process (batch or streaming), we find different execution patterns:

**Batch**:
- Processing in irregular time slots
- Processing in well-defined time slots
- Irregular processing, without defined pattern.

**Streaming**:
- Processing with continuous loads:
- Processing with irregular loads.

 To all this we must take into account the complexity of different types of workloads (low, medium, high intensity, critical, non-critical, etc.) or how the platform will behave in the event of a disaster, so defining the strategy does not It is always an easy task.

Next we are going to expose a strategy that balances between performance and cost efficiency

### **Core components**

### **Spark drivers and executors**



- **Multiple availability zones**: we have created Kubernetes node groups in 3 zones.

- **Dedicate node groups to Spark workloads** for both drivers and executors for each of the zones. Each node group allows scaling from 0 so that the times when there is no activity the cost is minimal.


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
  leader-elect: true
  expander: priority
  scale-down-enabled: true
  balance-similar-node-groups: false
  max-node-provision-time: 5m0s
  scan-interval: 10s
  scale-down-delay-after-add: 5m
  scale-down-unneeded-time: 1m
  skip-nodes-with-system-pods: true

expanderPriorities: |-
  50:
    - .*az3.*
  60:
    - .*az2.*
  70:
    - .*az1.*
```

### **About Isolate Spark applications**

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

## **References**

- [Gang Scheduling with Yunikorn](https://blog.cloudera.com/spark-on-kubernetes-gang-scheduling-with-yunikorn/)
