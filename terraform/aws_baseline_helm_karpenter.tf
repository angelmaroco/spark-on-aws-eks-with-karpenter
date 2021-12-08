resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter"
  repository       = "https://charts.karpenter.sh"
  chart            = "karpenter"
  version          = "0.5.1"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter.arn
  }

  set {
    name  = "controller.clusterName"
    value = module.eks.cluster_id
  }

  set {
    name  = "controller.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }
}
data "aws_iam_policy" "eks_worker_node" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "eks_cni_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_iam_policy" "ecr_read_only" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "KarpenterNodeRole" {
  name = "KarpenterNodeRole"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  managed_policy_arns = [
    data.aws_iam_policy.eks_worker_node.arn,
    data.aws_iam_policy.eks_cni_policy.arn,
    data.aws_iam_policy.ecr_read_only.arn,
    data.aws_iam_policy.ssm_managed_instance.arn
  ]
}

resource "aws_iam_instance_profile" "KarpenterNodeInstanceProfile" {
  name = "KarpenterNodeInstanceProfile"
  role = aws_iam_role.KarpenterNodeRole.name
}
resource "aws_iam_role" "karpenter" {
  name               = "karpenter"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:karpenter:karpenter"
        }
      }
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "karpenter-KarpenterControllerPolicy-Attach" {
  role       = aws_iam_role.karpenter.name
  policy_arn = aws_iam_policy.KarpenterControllerPolicy.arn
}

resource "aws_iam_policy" "KarpenterControllerPolicy" {
  name_prefix = "KarpenterControllerPolicy"
  description = "EKS KarpenterController policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.KarpenterControllerPolicy.json
}

data "aws_iam_policy_document" "KarpenterControllerPolicy" {
  statement {
    sid    = "KarpenterControllerPolicy"
    effect = "Allow"

    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:RunInstances",
      "ec2:CreateTags",
      "iam:PassRole",
      "ec2:TerminateInstances",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ssm:GetParameter"
    ]
    resources = ["*"]
  }
}


locals {
  subnetSelectorHigh = "*${var.tags.project}-${var.tags.environment}-${var.aws_baseline_karpenter.provisioner_high_priority_subnet_selector}*"
  subnetSelectorLow  = "*${var.tags.project}-${var.tags.environment}-${var.aws_baseline_karpenter.provisioner_low_priority_subnet_selector}*"
}

data "kubectl_path_documents" "path_provisioner_low_priority" {
  pattern = "${path.module}/templates/karpenter_prov_low_priority.yaml"
  vars = {
    name_provisioner     = var.aws_baseline_karpenter.provisioner_low_priority_name
    instanceType         = jsonencode(var.aws_baseline_karpenter.provisioner_low_priority_instance_type)
    arch                 = jsonencode(var.aws_baseline_karpenter.provisioner_low_priority_arch)
    capacityType         = jsonencode(var.aws_baseline_karpenter.provisioner_low_priority_capacity_type)
    instanceProfile      = aws_iam_instance_profile.KarpenterNodeInstanceProfile.name
    subnetSelector       = jsonencode(local.subnetSelectorLow)
    ttlSecondsAfterEmpty = var.aws_baseline_karpenter.provisioner_low_priority_ttl_second
  }
}

resource "kubectl_manifest" "provisioner_low_priority" {
  count     = length(data.kubectl_path_documents.path_provisioner_low_priority.documents)
  yaml_body = element(data.kubectl_path_documents.path_provisioner_low_priority.documents, count.index)
}




data "kubectl_path_documents" "path_provisioner_high_priority" {
  pattern = "${path.module}/templates/karpenter_prov_high_priority.yaml"
  vars = {
    name_provisioner     = var.aws_baseline_karpenter.provisioner_high_priority_name
    instanceType         = jsonencode(var.aws_baseline_karpenter.provisioner_high_priority_instance_type)
    arch                 = jsonencode(var.aws_baseline_karpenter.provisioner_high_priority_arch)
    capacityType         = jsonencode(var.aws_baseline_karpenter.provisioner_high_priority_capacity_type)
    instanceProfile      = aws_iam_instance_profile.KarpenterNodeInstanceProfile.name
    subnetSelector       = jsonencode(local.subnetSelectorHigh)
    ttlSecondsAfterEmpty = var.aws_baseline_karpenter.provisioner_high_priority_ttl_second
  }
}

resource "kubectl_manifest" "provisioner_high_priority" {
  count     = length(data.kubectl_path_documents.path_provisioner_high_priority.documents)
  yaml_body = element(data.kubectl_path_documents.path_provisioner_high_priority.documents, count.index)
}
