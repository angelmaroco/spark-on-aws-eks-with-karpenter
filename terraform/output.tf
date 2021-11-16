output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "account_region" {
  value = data.aws_region.current.name
}

output "grafana_username" {
  value = "admin"
}

output "grafana_password" {
  value     = random_password.grafana_password.result
  sensitive = true
}