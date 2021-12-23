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
  cluster_endpoint_private_access    = true
  cluster_endpoint_public_access     = true
  enable_irsa                        = true
  attach_worker_cni_policy           = true
  cluster_enabled_log_types          = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  worker_groups_name                 = "worker-group-on-demand"
  worker_groups_instance_type        = "t3.medium"
  worker_groups_additional_userdata  = ""
  worker_groups_asg_desired_capacity = 3
  worker_groups_asg_max_size         = 5
  worker_groups_asg_min_size         = 3
  worker_groups_kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=normal"
  worker_groups_suspended_processes  = ["AZRebalance"]

  worker_groups_spot_name                 = "worker-group-spot"
  worker_groups_spot_instance_type        = "t3a.medium"
  worker_groups_spot_additional_userdata  = ""
  worker_groups_spot_asg_desired_capacity = 0
  worker_groups_spot_asg_max_size         = 5
  worker_groups_spot_asg_min_size         = 0
  worker_groups_spot_kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=spot"
  worker_groups_spot_suspended_processes  = ["AZRebalance"]
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
