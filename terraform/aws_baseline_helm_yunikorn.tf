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
  repository       = "https://apache.github.io/yunikorn-release"
  chart            = "yunikorn"
  version          = "1.2.0"
  timeout          = 300

  values = [data.local_file.helm_chart_yunikorn.content]

  depends_on = [
    helm_release.grafana,
    helm_release.prometheus,
    helm_release.kubernetes-dashboard
  ]
}
