resource "kubernetes_namespace" "nydus" {
  metadata {
    name = "nydus-snapshotter"
  }
}

data "local_file" "helm_chart_nydus" {
  filename = "${path.module}/templates/nydus.yaml"
}

resource "helm_release" "nydus" {
  create_namespace = false
  namespace        = kubernetes_namespace.nydus.metadata.0.name
  name             = "nydus"
  repository       = "https://dragonflyoss.github.io/helm-charts/"
  chart            = "nydus-snapshotter"
  version          = "0.0.4"
  timeout          = 300

  values = [data.local_file.helm_chart_nydus.content]
}
