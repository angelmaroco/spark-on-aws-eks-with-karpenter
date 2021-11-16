resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

data "local_file" "helm_chart_grafana" {
  filename = "${path.module}/templates/grafana.yaml"
}

data "template_file" "file" {
  template = file("${path.module}/templates/prometheus.yaml")
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

resource "random_password" "grafana_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "grafana_password_secret" {
  name                    = "/grafana-${var.tags.environment}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "grafana_password_version" {
  secret_id     = aws_secretsmanager_secret.grafana_password_secret.id
  secret_string = random_password.grafana_password.result
}

resource "kubernetes_secret" "grafana-secrets" {
  metadata {
    name      = "grafana-credentials"
    namespace = kubernetes_namespace.monitoring.metadata.0.name
  }
  data = {
    adminUser     = var.aws_baseline_monitoring.grafana_admin_user
    adminPassword = random_password.grafana_password.result
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
