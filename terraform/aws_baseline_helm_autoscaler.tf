module "cluster_autoscaler" {
  source  = "lablabs/eks-cluster-autoscaler/aws"
  version = "1.6.1"

  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn

  settings = {
    "scale-down-delay-after-add" = "5m"
    "scale-down-unneeded"        = "1m"
  }

  depends_on = [
    module.eks
  ]
}

