locals {
  limit = var.limit - length(var.prefix) #reducing the length of the prefix from limit
  generated_name = (
    var.globally_unique ?
    (
      lookup(var.environment, "cluster_code", "") == "" ?
      "${var.environment.unique_name}-${var.resource_name}"
      :
      "${var.environment.unique_name}-${var.resource_name}-${var.environment.cluster_code}"
    )
    :
    (
      var.is_k8s ?
      "${var.resource_type}-${var.resource_name}"
      :
      "${var.environment.unique_name}-${var.resource_name}"
    )
  )
  name = (
    local.limit >= 32 ?
    (
      length(local.generated_name) > local.limit ? md5(local.generated_name) : local.generated_name
    )
    :
    (
      length(local.generated_name) > local.limit ?
      "${lookup(var.environment, "cluster_code", "")}-${var.resource_name}" : local.generated_name
    )
  )
  name_with_prefix = "${var.prefix}${local.name}"
}

output "name" {
  value = local.name_with_prefix
}