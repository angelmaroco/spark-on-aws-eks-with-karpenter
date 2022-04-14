tags = {
  terraform   = "true"
  environment = "dev"
  project     = "spark-on-aws-eks"
  region      = "eu-west-1"
}

aws_baseline_vpc = {
  vpc_name                         = "spark-on-aws-eks"
  cidr                             = "10.1.0.0/16"
  azs                              = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets                  = ["10.1.0.0/20", "10.1.16.0/20", "10.1.32.0/20"]
  public_subnets                   = ["10.1.48.0/20", "10.1.64.0/20", "10.1.80.0/20"]
  enable_nat_gateway               = true
  single_nat_gateway               = true
  one_nat_gateway_per_az           = false
  create_vpc                       = true
  default_vpc_enable_dns_hostnames = true
  default_vpc_enable_dns_support   = true
  enable_flow_log                  = true
  flow_log_destination_type        = "s3"
  enable_dns_hostnames             = true
  enable_dns_support               = true
}


aws_baseline_kms = {
  create_key              = true
  deletion_window_in_days = 7
  description             = "KMS key to encrypt objects inside s3 bucket logging"
  enable_key_rotation     = true
  enabled                 = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  name                    = "s3-logging"
}
aws_baseline_eks = {
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  enable_irsa                     = true
  attach_worker_cni_policy        = true
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  worker_groups_core_name                 = "core-group-on-demand"
  worker_groups_core_instance_type        = "m5a.large"
  worker_groups_core_additional_userdata  = ""
  worker_groups_core_asg_desired_capacity = 1
  worker_groups_core_asg_max_size         = 2
  worker_groups_core_asg_min_size         = 1
  worker_groups_core_kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=normal,node-type=core"
  worker_groups_core_suspended_processes  = ["AZRebalance"]

  worker_groups_spark_driver_low_cpu_name                 = "spark-group-driver-workload-low-cpu-on-demand"
  worker_groups_spark_driver_low_cpu_instance_type        = ["m5.large", "m5a.large"]
  worker_groups_spark_driver_low_cpu_additional_userdata  = ""
  worker_groups_spark_driver_low_cpu_asg_desired_capacity = 0
  worker_groups_spark_driver_low_cpu_asg_max_size         = 30
  worker_groups_spark_driver_low_cpu_asg_min_size         = 0
  worker_groups_spark_driver_low_cpu_kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=normal,workload=workload-low-cpu-driver"
  worker_groups_spark_driver_low_cpu_suspended_processes  = ["AZRebalance"]

  worker_groups_spark_executor_low_cpu_name                 = "spark-group-executor-workload-low-cpu-on-spot"
  worker_groups_spark_executor_low_cpu_instance_type        = ["m5.xlarge", "m5a.xlarge"]
  worker_groups_spark_executor_low_cpu_additional_userdata  = ""
  worker_groups_spark_executor_low_cpu_asg_desired_capacity = 0
  worker_groups_spark_executor_low_cpu_asg_max_size         = 30
  worker_groups_spark_executor_low_cpu_asg_min_size         = 0
  worker_groups_spark_executor_low_cpu_kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=spot,workload=workload-low-cpu-executor"
  worker_groups_spark_executor_low_cpu_suspended_processes  = ["AZRebalance"]

  worker_groups_jupyterhub_name                 = "jupyterhub-group-on-demand"
  worker_groups_jupyterhub_instance_type        = ["t3.medium", "t3a.medium"]
  worker_groups_jupyterhub_additional_userdata  = ""
  worker_groups_jupyterhub_asg_desired_capacity = 1
  worker_groups_jupyterhub_asg_max_size         = 1
  worker_groups_jupyterhub_asg_min_size         = 1
  worker_groups_jupyterhub_kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=normal,node-type=core-jupyterhub"
  worker_groups_jupyterhub_suspended_processes  = ["AZRebalance"]
}

aws_baseline_s3_spark = {
  block_public_acls       = true
  block_public_policy     = true
  bucket_name             = "spark-on-aws-eks"
  create_s3_bucket        = true
  force_destroy           = true
  restrict_public_buckets = true
  sse_algorithm           = "AES256"
  sse_prevent             = false
  versioning              = true
  spark_ui_path           = "spark-ui/"
  spark_data_path         = "data/"
  spark_output            = "output/"
}

aws_baseline_monitoring = {
  grafana_admin_user = "admin"
}
aws_baseline_ecr = {
  name                         = "spark-custom"
  image_tag_mutability         = "IMMUTABLE"
  image_scanning_configuration = "true"
  encryption_type              = "KMS"
}
