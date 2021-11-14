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

  set {
    name  = "sparkJobNamespace"
    value = "default"
  }

  set {
    name  = "webhook.enable"
    value = "true"
  }

  set {
    name  = "enable-metrics"
    value = "true"
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