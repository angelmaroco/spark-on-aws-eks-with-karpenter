resource "kubernetes_namespace" "yunikorn" {
  metadata {
    name = "yunikorn"
  }
}

data "local_file" "helm_chart_yunikorn" {
  filename = "${path.module}/templates/yunikorn_scheduler.yaml"
}


resource "helm_release" "yunikorn" {
  namespace        = kubernetes_namespace.yunikorn.metadata.0.name
  create_namespace = false
  name             = "yunikorn"
  repository       = "https://apache.github.io/incubator-yunikorn-release"
  chart            = "yunikorn"
  version          = "0.12.1"
  timeout          = 100

  values = [data.local_file.helm_chart_yunikorn.content]
}