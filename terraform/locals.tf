locals {
  name            = "cluster-${var.tags.project}-${var.tags.environment}"
  cluster_version = "1.22"
  region          = data.aws_region.current.name
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}
