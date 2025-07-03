output "image_id" {
  value = local.image_id
}

output "selector_labels" {
  value = {
    "app.kubernetes.io/name" = var.chart_name
    "app.kubernetes.io/instance" = "${var.chart_name}-app-chart"
    "app" = var.chart_name
  }
}

output "namespace" {
  value = var.namespace
}

output "debug_filtered_env_vars" {
  value = local.filtered_env_vars
}

output "debug_filtered_all_secrets" {
  value = local.filtered_all_secrets
}

output "debug_final_env" {
  value = local.final_env
}

output "debug_exclude_env_and_secret_values" {
  value = local.exclude_env_and_secret_values
}