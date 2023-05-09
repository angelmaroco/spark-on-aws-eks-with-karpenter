resource "kubernetes_namespace" "dragonfly" {
  metadata {
    name = "dragonfly-system"
  }
}

data "local_file" "helm_chart_dragonfly" {
  filename = "${path.module}/templates/dragonfly.yaml"
}

resource "helm_release" "dragonfly" {
  create_namespace = false
  namespace        = kubernetes_namespace.dragonfly.metadata.0.name
  name             = "dragonfly"
  repository       = "https://dragonflyoss.github.io/helm-charts/"
  chart            = "dragonfly"
  version          = "1.0.2"
  timeout          = 300

  values = [data.local_file.helm_chart_dragonfly.content]
}
