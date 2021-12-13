resource "kubernetes_namespace" "spark-operator" {
  metadata {
    name = "spark-operator"
  }
}

resource "helm_release" "spark-operator" {
  chart      = "spark-operator"
  name       = "spark-operator"
  namespace  = kubernetes_namespace.spark-operator.metadata.0.name
  repository = "https://googlecloudplatform.github.io/spark-on-k8s-operator"
  version    = "1.1.14"

  set {
    name  = "sparkJobNamespace"
    value = "default"
  }

  set {
    name  = "enableWebhook"
    value = "true"
  }

  set {
    name  = "enableMetrics"
    value = "true"
  }

  set {
    name  = "replicaCount"
    value = "1"

  }
}

resource "kubernetes_service_account" "spark-service-account" {
  metadata {
    name = "spark"
  }
}

resource "kubernetes_cluster_role_binding" "spark-cluster-role-binding" {
  metadata {
    name = "spark-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "spark"
    namespace = "default"
  }
}
