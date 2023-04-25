data "local_file" "helm_chart_aws_node_termination" {
  filename = "${path.module}/templates/aws_node_termination_handler.yaml"
}

resource "helm_release" "aws_node_termination_handler" {
  create_namespace = false
  namespace        = "kube-system"
  name             = "aws-node-termination-handler"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-node-termination-handler"
  version          = "0.21.0"
  timeout          = 300

  values = [data.local_file.helm_chart_aws_node_termination.content]
}
