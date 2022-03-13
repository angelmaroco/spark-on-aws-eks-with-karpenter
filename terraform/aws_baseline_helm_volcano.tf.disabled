resource "kubernetes_namespace" "volcano" {
  metadata {
    name = "volcano"
  }
}

resource "helm_release" "example" {
  name      = "volcano-scheduler"
  chart     = "./templates/volcano"
  namespace = kubernetes_namespace.volcano.metadata.0.name
  timeout   = 600
}
