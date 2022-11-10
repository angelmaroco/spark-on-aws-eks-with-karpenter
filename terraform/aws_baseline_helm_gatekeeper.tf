resource "kubernetes_namespace" "gatekeeper" {
  metadata {
    name = "gatekeeper"
  }
}

data "local_file" "helm_chart_gatekeeper" {
  filename = "${path.module}/templates/gatekeeper.yaml"
}

resource "helm_release" "gatekeeper" {
  namespace        = kubernetes_namespace.gatekeeper.metadata.0.name
  create_namespace = false
  name             = "gatekeeper"
  repository       = "https://open-policy-agent.github.io/gatekeeper/charts"
  version          = "v3.10.0"
  chart            = "gatekeeper"
  timeout          = 120

  values = [data.local_file.helm_chart_gatekeeper.content]
}

resource "kubectl_manifest" "gatekeeper_mutation_node_selector_jupyter" {
  yaml_body = <<-YAML
  apiVersion: mutations.gatekeeper.sh/v1beta1
  kind: Assign
  metadata:
    name: node-selector-jupyter
    namespace: gatekeeper
  spec:
    applyTo:
      - groups: [""]
        kinds: ["Pod"]
        versions: ["v1"]
    match:
      scope: Namespaced
      name: jupyter-notebook-spark*
      kinds:
        - apiGroups: ["*"]
          kinds: ["Pod"]
      namespaces: ["spark-users"]
    location: "spec.nodeSelector"
    parameters:
      assign:
        value:
          node-type: "workload-jupyterhub-user-spark"
  YAML

  depends_on = [
    helm_release.gatekeeper
  ]
}

resource "kubectl_manifest" "gatekeeper_mutation_node_toleration_jupyter" {
  yaml_body = <<-YAML
  apiVersion: mutations.gatekeeper.sh/v1beta1
  kind: Assign
  metadata:
    name: node-toleration-jupyter
    namespace: gatekeeper
  spec:
    applyTo:
      - groups: [""]
        kinds: ["Pod"]
        versions: ["v1"]
    match:
      scope: Namespaced
      name: jupyter-notebook-spark*
      kinds:
        - apiGroups: ["*"]
          kinds: ["Pod"]
      namespaces: ["spark-users"]
    location: "spec.tolerations"
    parameters:
      assign:
        value:
          - key: node-type
            operator: "Equal"
            value: "workload-jupyterhub-user-spark"
  YAML

  depends_on = [
    helm_release.gatekeeper
  ]
}
