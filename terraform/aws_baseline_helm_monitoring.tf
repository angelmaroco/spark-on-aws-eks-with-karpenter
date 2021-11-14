resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

data "local_file" "helm_chart_grafana" {
  filename = "${path.module}/templates/grafana.yaml"
}

data "template_file" "file" {
  template = "${file("${path.module}/templates/prometheus.yaml")}"
}

data "local_file" "helm_chart_dashboard" {
  filename = "${path.module}/templates/dashboard.yaml"
}


resource "helm_release" "prometheus" {
  chart      = "prometheus"
  name       = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata.0.name
  repository = "https://charts.helm.sh/stable"

  values = [data.template_file.file.rendered]
}

resource "helm_release" "grafana" {
  chart      = "grafana"
  name       = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata.0.name
  repository = "https://charts.helm.sh/stable"

  values = [data.local_file.helm_chart_grafana.content]
}

resource "kubernetes_secret" "grafana-secrets" {
  metadata {
    name      = "grafana-credentials"
    namespace = kubernetes_namespace.monitoring.metadata.0.name
  }
  data = {
    adminUser     = "demo"
    adminPassword = "demo"
  }
}


resource "helm_release" "kubernetes-dashboard" {

  name = "kubernetes-dashboard"

  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  namespace  = kubernetes_namespace.monitoring.metadata.0.name

  values = [data.local_file.helm_chart_dashboard.content]
}


data "kubernetes_service" "grafana" {
  depends_on = [
    helm_release.grafana
  ]

  metadata {
    namespace = helm_release.grafana.namespace
    name      = "grafana"
  }
}

data "kubernetes_service" "prometheus" {
  depends_on = [
    helm_release.prometheus
  ]

  metadata {
    namespace = helm_release.prometheus.namespace
    name      = "prometheus-server"
  }
}

data "kubernetes_service" "kubernetes-dashboard" {
  depends_on = [
    helm_release.kubernetes-dashboard
  ]

  metadata {
    namespace = helm_release.kubernetes-dashboard.namespace
    name      = "kubernetes-dashboard"
  }
}