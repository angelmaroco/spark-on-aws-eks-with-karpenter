resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

data "local_file" "helm_chart_karpenter" {
  filename = "${path.module}/templates/karpenter.yaml"
}

resource "helm_release" "karpenter" {
  namespace        = kubernetes_namespace.karpenter.metadata.0.name
  create_namespace = false
  name             = "karpenter"
  repository       = "https://charts.karpenter.sh"
  chart            = "karpenter"
  version          = "v0.16.3"
  timeout          = 300

  values = [data.local_file.helm_chart_karpenter.content]

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_karpenter.iam_role_arn
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_id
  }

  set {
    name  = "clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }
}

data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "ecr_read_only" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
  role       = module.eks.worker_iam_role_name
  policy_arn = data.aws_iam_policy.ssm_managed_instance.arn
}

resource "aws_iam_role_policy_attachment" "karpenter_ecr_readonly" {
  role       = module.eks.worker_iam_role_name
  policy_arn = data.aws_iam_policy.ecr_read_only.arn
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${local.name}"
  role = module.eks.worker_iam_role_name
}

module "iam_assumable_role_karpenter" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.7.0"
  create_role                   = true
  role_name                     = "karpenter-controller-${local.name}"
  provider_url                  = module.eks.cluster_oidc_issuer_url
  oidc_fully_qualified_subjects = ["system:serviceaccount:karpenter:karpenter"]
}

resource "aws_iam_role_policy" "karpenter_contoller" {
  name = "karpenter-policy-${local.name}"
  role = module.iam_assumable_role_karpenter.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter",
          "pricing:GetProducts",
          "ec2:DescribeSpotPriceHistory"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "kubectl_manifest" "karpenter_provisioner_jupyterhub_user" {
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: "karpenter-provisioner-jupyterhub-user"
  spec:
    taints:
      - key: node-type
        value: workload-jupyterhub-user
        effect: NoSchedule
    labels:
      node-type: "workload-jupyterhub-user"
    requirements:
      - key: "karpenter.k8s.aws/instance-family"
        operator: In
        values: ["m6a", "m5a", "m5"]
      - key: "karpenter.k8s.aws/instance-size"
        operator: In
        values: ["xlarge", "2xlarge"]
      - key: "kubernetes.io/arch"
        operator: In
        values: ["amd64"]
      - key: "karpenter.sh/capacity-type"
        operator: In
        values: ["spot", "on-demand"]
    provider:
      tags:
        Name: "karpenter-provisioner-jupyterhub-user"
      instanceProfile: "KarpenterNodeInstanceProfile-cluster-spark-on-aws-eks-dev"
      subnetSelector:
          Name: "*spark-on-aws-eks-dev-private*"
      securityGroupSelector:
          Name: "cluster-spark-on-aws-eks-dev-eks_worker_sg"
    ttlSecondsAfterEmpty: 30
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_provisioner_jupyterhub_user_spark" {
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: "karpenter-provisioner-jupyterhub-user-spark"
  spec:
    taints:
      - key: node-type
        value: workload-jupyterhub-user-spark
        effect: NoSchedule
    labels:
      node-type: "workload-jupyterhub-user-spark"
    requirements:
      - key: "karpenter.k8s.aws/instance-family"
        operator: In
        values: ["m5","m5a","m6a"]
      - key: "kubernetes.io/arch"
        operator: In
        values: ["amd64"]
      - key: "karpenter.sh/capacity-type"
        operator: In
        values: ["spot", "on-demand"]
    provider:
      tags:
        Name: "karpenter-provisioner-jupyterhub-user-spark"
      instanceProfile: "KarpenterNodeInstanceProfile-cluster-spark-on-aws-eks-dev"
      subnetSelector:
          Name: "*spark-on-aws-eks-dev-private*"
      securityGroupSelector:
          Name: "cluster-spark-on-aws-eks-dev-eks_worker_sg"
    ttlSecondsAfterEmpty: 30
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}
