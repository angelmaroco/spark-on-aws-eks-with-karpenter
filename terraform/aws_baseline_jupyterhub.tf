
data "local_file" "helm_chart_jupyterhub" {
  filename = "${path.module}/templates/jupyterhub.yaml"
}
resource "kubernetes_namespace" "jupyterhub" {
  metadata {
    name = "jupyterhub"
  }
}

resource "kubernetes_namespace" "spark_users" {
  metadata {
    name = "spark-users"
  }
}


resource "kubernetes_service_account" "spark-service-account-jupyter" {
  metadata {
    name      = "spark-jupyter"
    namespace = "jupyterhub"
  }
}


resource "kubernetes_cluster_role_binding" "spark-cluster-role-binding-jupyter" {
  metadata {
    name = "spark-cluster-role-binding-jupyter"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "spark-jupyter"
    namespace = "jupyterhub"
  }
}

resource "helm_release" "jupyterhub" {
  namespace        = kubernetes_namespace.jupyterhub.metadata.0.name
  create_namespace = false
  name             = "jupyterhub"
  repository       = "https://jupyterhub.github.io/helm-chart/"
  chart            = "jupyterhub"
  version          = "2.0.0"
  timeout          = 300

  values = [data.local_file.helm_chart_jupyterhub.content]

  set {
    name  = "singleuser.image.name"
    value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/jupyter-custom"
  }

  set {
    name  = "singleuser.image.tag"
    value = "3.2.0"
  }
}
