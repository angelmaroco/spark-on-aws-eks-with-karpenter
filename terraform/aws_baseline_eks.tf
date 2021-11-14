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

  worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]

  worker_groups = [
    {
      name                          = var.aws_baseline_eks.worker_groups_name
      instance_type                 = var.aws_baseline_eks.worker_groups_instance_type
      additional_userdata           = var.aws_baseline_eks.worker_groups_additional_userdata
      asg_desired_capacity          = var.aws_baseline_eks.worker_groups_asg_desired_capacity
      asg_max_size                  = var.aws_baseline_eks.worker_groups_asg_max_size
      asg_min_size                  = var.aws_baseline_eks.worker_groups_asg_min_size
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
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
}

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.aws_baseline_vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.aws_baseline_vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}
