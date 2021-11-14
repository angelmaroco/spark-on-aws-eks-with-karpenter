data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.23.0"

  # see locals.tf
  cluster_name    = local.name
  cluster_version = local.cluster_version

  vpc_id  = module.aws_baseline_vpc.vpc_id
  subnets = [module.aws_baseline_vpc.private_subnets[0], module.aws_baseline_vpc.private_subnets[1]]

  cluster_endpoint_private_access = var.aws_baseline_eks.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.aws_baseline_eks.cluster_endpoint_public_access
  cluster_enabled_log_types       = var.aws_baseline_eks.cluster_enabled_log_types

  enable_irsa = true

  attach_worker_cni_policy = true

  worker_additional_security_group_ids = [module.sg_eks_worker_group_all.this_security_group_id]

  workers_additional_policies = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]

  worker_groups = [
    {
      name                          = var.aws_baseline_eks.worker_groups_name
      instance_type                 = var.aws_baseline_eks.worker_groups_instance_type
      additional_userdata           = var.aws_baseline_eks.worker_groups_additional_userdata
      asg_desired_capacity          = var.aws_baseline_eks.worker_groups_asg_desired_capacity
      asg_max_size                  = var.aws_baseline_eks.worker_groups_asg_max_size
      asg_min_size                  = var.aws_baseline_eks.worker_groups_asg_min_size
      additional_security_group_ids = [module.sg_eks_worker_group_one.this_security_group_id]
      write_kubeconfig              = var.aws_baseline_eks.write_kubeconfig
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.name}"
          "propagate_at_launch" = "false"
          "value"               = "owned"
        }
      ]
    }

  ]

  tags = var.tags

  depends_on = [
    module.sg_eks_worker_group_one,
    module.sg_eks_worker_group_all
  ]
}

module "sg_eks_worker_group_one" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "3.2.0"
  name                = "sg_eks_worker_group_one"
  description         = "Security group for eks worker group"
  vpc_id              = module.aws_baseline_vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]

  ingress_with_cidr_blocks = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_rules = ["all-all"]
  tags         = var.tags
}

module "sg_eks_worker_group_all" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "3.2.0"
  name                = "sg_eks_worker_group_all"
  description         = "Security group for eks worker group"
  vpc_id              = module.aws_baseline_vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]

  ingress_with_cidr_blocks = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_rules = ["all-all"]
  tags         = var.tags
}