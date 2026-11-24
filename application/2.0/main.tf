locals {
  # spec.release.image can be either:
  # 1. A simple string: "gcr.io/project/app:v1.0"
  # 2. An object: { url = "gcr.io/project/app:v1.0", build_id = "abc123" }
  release_image = lookup(var.values.spec.release, "image", "NOT_FOUND")

  # Detect if image is an object (has "url" key) or a simple string
  image_id = try(local.release_image.url, local.release_image)

  # If object schema, use build_id from object; otherwise empty string
  build_id = try(local.release_image.build_id, "")

  advanced_config_values       = lookup(local.advanced_config, "values", {})
  kubernetes_node_pool_details = lookup(var.inputs, "kubernetes_node_pool_details", {})
  common_advanced              = lookup(lookup(var.values, "advanced", {}), "common", {})
  all_secrets                  = lookup(local.common_advanced, "include_common_env_secrets", false) ? var.environment.secrets : {}
  advanced_config              = lookup(local.common_advanced, "app_chart", {})
  common_environment_variables = jsondecode(lookup(local.common_advanced, "include_common_env_variables", false) ? jsonencode(var.environment.common_environment_variables) : jsonencode({}))
  spec_environment_variables   = lookup(var.values.spec, "env", {})
  env_vars                     = merge(local.common_environment_variables, local.spec_environment_variables)
  deployment_id                = lookup(local.common_advanced, "pass_deployment_id", false) ? var.environment.deployment_id : ""
  taints                       = lookup(local.kubernetes_node_pool_details, "taints", [])
  chart_name                   = lookup(lookup(lookup(var.values, "metadata", {}), "labels", {}), "resourceName", var.chart_name)
  parsed_taints = [
    for taint in local.taints : {
      key      = taint.key
      value    = taint.value
      effect   = taint.effect
      operator = "Equal"
    }
  ]
  tolerations = lookup(local.advanced_config_values, "tolerations", {})
  node_selector = merge(
    lookup(local.advanced_config_values, "node_selector", {}),
    lookup(local.kubernetes_node_pool_details, "node_selector", {})
  )
  build_id_env = lookup(local.advanced_config_values, "include_build_id_env", false) ? { BUILD_ID = local.build_id } : {}
  adv_tolerations = [
    for toleration_key, toleration in local.tolerations :
    {
      key      = toleration.key
      operator = toleration.operator
      effect   = toleration.effect
      value    = toleration.value
    }
  ]
  all_tolerations = distinct(concat(local.adv_tolerations, local.parsed_taints, lookup(var.environment, "default_tolerations", [])))

  size = lookup(lookup(var.values.spec, "runtime", {}), "size", {
    cpu          = "1000m"
    cpu_limit    = "1000m"
    memory       = "1000Mi"
    memory_limit = "1000Mi"
  })

  cpu          = lookup(local.size, "cpu", "1000m")
  cpu_limit    = lookup(local.size, "cpu_limit", local.cpu)
  memory       = lookup(local.size, "memory", "1000Mi")
  memory_limit = lookup(local.size, "memory_limit", local.memory)

  processed_size = {
    cpu          = local.cpu
    cpu_limit    = local.cpu_limit
    memory       = local.memory
    memory_limit = local.memory_limit
  }

  type           = lookup(var.values.spec, "type", "application")
  pvcs           = lookup(var.values.spec, "persistent_volume_claims", {})
  instance_count = lookup(lookup(var.values.spec, "runtime", {}), "instance_count", 1)
  sts_pvcs = local.type == "statefulset" ? merge(slice(flatten([
    for idx in range(local.instance_count) : {
      for pvc_name, pvc_spec in local.pvcs : "${pvc_name}-vol-${var.chart_name}-${idx}" => merge(pvc_spec, { index = idx })
  }]), 0, local.instance_count)...) : {}

  pod_distribution = lookup(local.advanced_config_values, "pod_distribution", {})
  sidecars         = lookup(var.values.spec, "sidecars", lookup(local.advanced_config_values, "sidecars", {}))
  init_containers  = lookup(var.values.spec, "init_containers", lookup(local.advanced_config_values, "init_containers", {}))
  exclude_env_and_secret_values = try(
    var.values.advanced.common.app_chart.values.exclude_env_and_secret_values,
    []
  )

  filtered_env_vars = {
    for k, v in local.env_vars :
    k => v
    if !(contains(local.exclude_env_and_secret_values, v))
  }

  filtered_all_secrets = {
    for k, v in local.all_secrets :
    k => v
    if !(contains(local.exclude_env_and_secret_values, v))
  }
  # Keep resolved environment values out of Helm release history and metadata.
  effective_env = merge(
    lookup(var.environment, "global_variables", {}),
    local.filtered_env_vars,
    local.build_id_env,
    local.filtered_all_secrets,
    length(local.deployment_id) > 0 ? { deployment_id = local.deployment_id } : {}
  )
  allow_dots_in_env = lookup(local.advanced_config_values, "allow_dots_in_env", false)
  secret_env = {
    for k, v in local.effective_env :
    (!local.allow_dots_in_env && strcontains(k, ".") ? upper(replace(k, ".", "_")) : k) => tostring(v)
  }
  safe_sidecars = {
    for name, container in local.sidecars : name => merge(container, {
      env = {}
      additional_k8s_env = concat(
        [for key in keys(lookup(container, "env", {})) : {
          name      = key
          valueFrom = { secretKeyRef = { name = "${var.chart_name}-env-${substr(sha256("sidecar/${name}"), 0, 10)}", key = key } }
        }],
        lookup(container, "additional_k8s_env", [])
      )
    })
  }
  safe_init_containers = {
    for name, container in local.init_containers : name => merge(container, {
      env = {}
      additional_k8s_env = concat(
        [for key in keys(lookup(container, "env", {})) : {
          name      = key
          valueFrom = { secretKeyRef = { name = "${var.chart_name}-env-${substr(sha256("init/${name}"), 0, 10)}", key = key } }
        }],
        lookup(container, "additional_k8s_env", [])
      )
    })
  }
  safe_advanced_values = merge(local.advanced_config_values, {
    sidecars        = local.safe_sidecars
    init_containers = local.safe_init_containers
  })
  helm_values = merge(var.values, {
    spec = merge(var.values.spec, { env = {}, sidecars = local.safe_sidecars, init_containers = local.safe_init_containers })
    advanced = merge(lookup(var.values, "advanced", {}), {
      common = merge(local.common_advanced, {
        app_chart = merge(local.advanced_config, { values = local.safe_advanced_values })
      })
    })
  })
}

resource "kubernetes_secret_v1" "app_env" {
  metadata {
    name      = "${var.chart_name}-env"
    namespace = var.namespace
  }
  data = sensitive(local.secret_env)
  type = "Opaque"
}

resource "kubernetes_secret_v1" "sidecar_env" {
  for_each = local.sidecars
  metadata {
    name      = "${var.chart_name}-env-${substr(sha256("sidecar/${each.key}"), 0, 10)}"
    namespace = var.namespace
  }
  data = sensitive(lookup(each.value, "env", {}))
  type = "Opaque"
}

resource "kubernetes_secret_v1" "init_env" {
  for_each = local.init_containers
  metadata {
    name      = "${var.chart_name}-env-${substr(sha256("init/${each.key}"), 0, 10)}"
    namespace = var.namespace
  }
  data = sensitive(lookup(each.value, "env", {}))
  type = "Opaque"
}

resource "helm_release" "app-chart" {
  depends_on = [module.sts-pvc]

  name             = "${var.chart_name}-app-chart"
  chart            = "${path.module}/app-chart"
  namespace        = var.namespace
  version          = "0.3.0"
  create_namespace = var.namespace == "default" ? false : true
  timeout          = lookup(local.advanced_config, "timeout", 300)
  wait             = lookup(local.advanced_config, "wait", false)
  atomic           = lookup(local.advanced_config, "atomic", false)
  max_history      = 10
  cleanup_on_fail  = lookup(local.advanced_config, "cleanup_on_fail", true)
  values = [
    yamlencode(local.helm_values),
    yamlencode({
      metadata = {
        name        = var.chart_name
        annotations = merge(var.annotations, { buildId = local.build_id, "facets.cloud/env-secret-resource-version" = jsonencode(concat([kubernetes_secret_v1.app_env.metadata[0].resource_version], [for secret in kubernetes_secret_v1.sidecar_env : secret.metadata[0].resource_version], [for secret in kubernetes_secret_v1.init_env : secret.metadata[0].resource_version])) })
        labels      = var.labels
      }
      spec = {
        release = {
          image = local.image_id
        }
        runtime = merge(
          lookup(var.values.spec, "runtime", {}),
          {
            size = local.processed_size
          }
        )
      }
    }),
    yamlencode({
      advanced = {
        common = {
          app_chart = {
            values = {
              tolerations      = local.all_tolerations
              node_selector    = local.node_selector
              pod_distribution = local.pod_distribution
              init_containers  = local.safe_init_containers
              sidecars         = local.safe_sidecars
              additional_k8s_env_from = concat(
                lookup(local.advanced_config_values, "additional_k8s_env_from", []),
                [{ secretRef = { name = kubernetes_secret_v1.app_env.metadata[0].name } }]
              )
            }
          }
        }
      }
    })
  ]
}

module "sts-pvc" {
  for_each = local.sts_pvcs

  source          = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name            = each.key
  namespace       = var.namespace
  access_modes    = [each.value.access_mode]
  volume_size     = each.value.storage_size
  provisioned_for = "${var.chart_name}-app-chart-${each.value.index}"
  instance_name   = local.chart_name
  kind            = "service"
  additional_labels = merge({
    "app"                        = var.chart_name
    "app.kubernetes.io/name"     = var.chart_name
    "app.kubernetes.io/instance" = "${var.chart_name}-app-chart"
  }, var.labels)
  cloud_tags = var.environment.cloud_tags
}
