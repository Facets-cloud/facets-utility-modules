mock_provider "helm" {}
mock_provider "kubernetes" {}

run "env_values_stay_out_of_helm" {
  command = plan
  variables {
    chart_name     = "test"
    vpa_release_id = ""
    namespace      = "default"
    annotations    = {}
    labels         = {}
    inputs         = {}
    environment = {
      global_variables             = { GLOBAL_TOKEN = "global-canary" }
      common_environment_variables = { COMMON_TOKEN = "common-canary" }
      secrets                      = { SECRET_TOKEN = "secret-canary" }
      cloud_tags                   = {}
    }
    values = {
      spec = { release = { image = "example/test:1" }, env = { API_TOKEN = "fixture-canary-value", "app.mode" = "dotted-canary" }, sidecars = { worker = { image = "example/worker", env = { API_KEY = "sidecar-canary" } } }, init_containers = { setup = { image = "example/setup", env = { API_KEY = "init-canary" } } } }
      advanced = { common = {
        include_common_env_variables = true
        include_common_env_secrets   = true
        app_chart                    = { values = { additional_k8s_env_from = [{ configMapRef = { name = "existing" } }] } }
      } }
    }
  }
  assert {
    condition     = alltrue([for canary in ["fixture-canary-value", "global-canary", "common-canary", "secret-canary", "dotted-canary", "sidecar-canary", "init-canary"] : !strcontains(nonsensitive(join("\n", [helm_release.app-chart.values[0], helm_release.app-chart.values[2]])), canary)])
    error_message = "Application environment values must never appear in Helm values."
  }
  assert {
    condition = nonsensitive(kubernetes_secret_v1.app_env.data) == tomap({
      API_TOKEN = "fixture-canary-value", GLOBAL_TOKEN = "global-canary", COMMON_TOKEN = "common-canary", SECRET_TOKEN = "secret-canary", APP_MODE = "dotted-canary"
    })
    error_message = "All environment sources must reach the Kubernetes Secret using chart-compatible keys."
  }
  assert {
    condition     = yamldecode(helm_release.app-chart.values[2]).advanced.common.app_chart.values.additional_k8s_env_from == [{ configMapRef = { name = "existing" } }, { secretRef = { name = "test-env" } }]
    error_message = "The new envFrom must preserve existing sources and take precedence."
  }
  assert {
    condition     = nonsensitive(kubernetes_secret_v1.sidecar_env["worker"].data["API_KEY"]) == "sidecar-canary" && nonsensitive(kubernetes_secret_v1.init_env["setup"].data["API_KEY"]) == "init-canary"
    error_message = "Sidecar and init container values must reach their own Secrets."
  }
}
