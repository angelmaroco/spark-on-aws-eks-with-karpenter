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

data "local_file" "helm_chart_spark_history_server" {
  filename = "${path.module}/templates/spark_history_server.yaml"
}


resource "helm_release" "prometheus" {
  chart      = "prometheus"
  name       = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata.0.name
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "15.8.1"
  timeout    = 600

  values = [data.template_file.file.rendered]
}

resource "helm_release" "grafana" {
  chart      = "grafana"
  name       = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata.0.name
  repository = "https://grafana.github.io/helm-charts"
  version    = "6.26.2"
  timeout    = 600

  values = [data.local_file.helm_chart_grafana.content]
}

resource "random_password" "grafana_password" {
  length  = 16
  special = false
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
  version    = "5.4.1"
  values     = [data.local_file.helm_chart_dashboard.content]
}

resource "helm_release" "spark-history-server" {

  name = "spark-history-server"

  repository = "https://charts.spot.io"
  chart      = "spark-history-server"
  version    = "1.5.0"
  namespace  = kubernetes_namespace.monitoring.metadata.0.name
  timeout    = 600

  values = [data.local_file.helm_chart_spark_history_server.content]

  set {
    name  = "s3.enableS3"
    value = "true"
  }
  set {
    name  = "s3.enableIAM"
    value = "true"
  }

  set {
    name  = "s3.secret"
    value = "aws-secrets"
  }

  set {
    name  = "s3.logDirectory"
    value = "s3a://${module.aws_baseline_s3_spark.bucket_id}/${var.aws_baseline_s3_spark.spark_ui_path}"
  }
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

data "kubernetes_service" "spark-history-server" {
  depends_on = [
    helm_release.spark-history-server
  ]

  metadata {
    namespace = helm_release.spark-history-server.namespace
    name      = "spark-history-server"
  }
}
