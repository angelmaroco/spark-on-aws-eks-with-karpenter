## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.4.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.13.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.6.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.4.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.6.1 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_baseline_kms"></a> [aws\_baseline\_kms](#module\_aws\_baseline\_kms) | clouddrove/kms/aws | 0.15.0 |
| <a name="module_aws_baseline_s3_spark"></a> [aws\_baseline\_s3\_spark](#module\_aws\_baseline\_s3\_spark) | cloudposse/s3-bucket/aws | 0.44.0 |
| <a name="module_aws_baseline_vpc"></a> [aws\_baseline\_vpc](#module\_aws\_baseline\_vpc) | terraform-aws-modules/vpc/aws | ~> 3.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 17.23.0 |
| <a name="module_endpoints"></a> [endpoints](#module\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 3.11.0 |
| <a name="module_iam_assumable_role_karpenter"></a> [iam\_assumable\_role\_karpenter](#module\_iam\_assumable\_role\_karpenter) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 4.7.0 |
| <a name="module_sg_eks_worker_group_all"></a> [sg\_eks\_worker\_group\_all](#module\_sg\_eks\_worker\_group\_all) | terraform-aws-modules/security-group/aws | 3.2.0 |
| <a name="module_sg_eks_worker_group_on_demand"></a> [sg\_eks\_worker\_group\_on\_demand](#module\_sg\_eks\_worker\_group\_on\_demand) | terraform-aws-modules/security-group/aws | 3.2.0 |
| <a name="module_sg_eks_worker_group_spot"></a> [sg\_eks\_worker\_group\_spot](#module\_sg\_eks\_worker\_group\_spot) | terraform-aws-modules/security-group/aws | 3.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ecr_repository.spark-custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.spark-custom-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_iam_instance_profile.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role_policy.karpenter_contoller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.karpenter_ecr_readonly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.karpenter_ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket_object.dataset_example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.python_example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.spark_data_path](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.spark_output_path](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.spark_ui_path](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_security_group.non_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [helm_release.grafana](https://registry.terraform.io/providers/hashicorp/helm/2.4.1/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/2.4.1/docs/resources/release) | resource |
| [helm_release.kubernetes-dashboard](https://registry.terraform.io/providers/hashicorp/helm/2.4.1/docs/resources/release) | resource |
| [helm_release.prometheus](https://registry.terraform.io/providers/hashicorp/helm/2.4.1/docs/resources/release) | resource |
| [helm_release.spark-history-server](https://registry.terraform.io/providers/hashicorp/helm/2.4.1/docs/resources/release) | resource |
| [helm_release.spark-operator](https://registry.terraform.io/providers/hashicorp/helm/2.4.1/docs/resources/release) | resource |
| [kubernetes_cluster_role_binding.spark-cluster-role-binding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_namespace.karpenter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.spark-operator](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.grafana-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service_account.spark-service-account](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [null_resource.build-and-push-ecr](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.grafana_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy.ecr_read_only](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy.ssm_managed_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.aws_baseline_kms_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [kubernetes_service.grafana](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |
| [kubernetes_service.kubernetes-dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |
| [kubernetes_service.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |
| [kubernetes_service.spark-history-server](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |
| [local_file.helm_chart_dashboard](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |
| [local_file.helm_chart_grafana](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |
| [local_file.helm_chart_spark_history_server](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |
| [template_file.file](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_baseline_ecr"></a> [aws\_baseline\_ecr](#input\_aws\_baseline\_ecr) | n/a | `map(string)` | n/a | yes |
| <a name="input_aws_baseline_eks"></a> [aws\_baseline\_eks](#input\_aws\_baseline\_eks) | n/a | `any` | n/a | yes |
| <a name="input_aws_baseline_karpenter"></a> [aws\_baseline\_karpenter](#input\_aws\_baseline\_karpenter) | n/a | `any` | n/a | yes |
| <a name="input_aws_baseline_kms"></a> [aws\_baseline\_kms](#input\_aws\_baseline\_kms) | n/a | `map(string)` | n/a | yes |
| <a name="input_aws_baseline_monitoring"></a> [aws\_baseline\_monitoring](#input\_aws\_baseline\_monitoring) | n/a | `any` | n/a | yes |
| <a name="input_aws_baseline_s3_spark"></a> [aws\_baseline\_s3\_spark](#input\_aws\_baseline\_s3\_spark) | n/a | `any` | n/a | yes |
| <a name="input_aws_baseline_vpc"></a> [aws\_baseline\_vpc](#input\_aws\_baseline\_vpc) | n/a | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | n/a |
| <a name="output_account_region"></a> [account\_region](#output\_account\_region) | n/a |
| <a name="output_grafana_password"></a> [grafana\_password](#output\_grafana\_password) | n/a |
| <a name="output_grafana_username"></a> [grafana\_username](#output\_grafana\_username) | n/a |
