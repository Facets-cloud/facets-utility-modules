
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