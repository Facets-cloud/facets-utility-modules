locals {
  deployment_context           = jsondecode(file("/sources/primary/capillary-cloud-tf/deploymentcontext.json"))
  cluster_id                   = lookup(lookup(local.deployment_context, "cluster", {}), "id")

  labels = {
    display_name     = var.name
    resource_name    = var.instance_name
    resource_kind    = var.instance.kind
    environment_unique_name      = var.environment.unique_name
    cluster_id      = local.cluster_id
  }

  name = md5("${var.instance_name}-${var.environment.unique_name}-${var.name}")
  namespace = "tekton-pipelines"

  k8s_init_commands = <<-EOT
    #!/bin/bash
    set -e
    mkdir -p /workspace/.kube
    echo -n "$FACETS_USER_KUBECONFIG" | base64 -d > /workspace/.kube/config
    export KUBECONFIG=/workspace/.kube/config
  EOT

  steps_with_k8s_env = [
    for step in var.steps : merge(
      step,
      {
        env = concat(
          lookup(step, "env", []),
          [
            {
              name  = "KUBECONFIG"
              value = "/workspace/.kube/config"
            }
          ]
        )
      }
    )
  ]

  stepaction_data = {
    apiVersion = "tekton.dev/v1beta1"
    kind       = "StepAction"
    metadata = {
      name      = module.stepaction_name.name
      namespace = local.namespace
      labels = local.labels
    }
    spec = {
      image = "facetscloud/actions-credentials-setup:v1.0.0"
      script = local.k8s_init_commands
      params = [
        {
          name = "FACETS_USER_KUBECONFIG"
          type = "string"
        }
      ]
      env = [
        {
          name = "FACETS_USER_KUBECONFIG"
          value = "$(params.FACETS_USER_KUBECONFIG)"
        }
      ]
    }
  }

  task_data = {
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = module.task_name.name
      namespace = local.namespace
      labels = local.labels
    }
    spec = merge(
      {
        description = var.description == "" ? module.task_name.name : var.description,
        steps = concat([
          {
            name = "setup-credentials"
            ref = {
              name = module.stepaction_name.name
            }
            params = [
              {
                name = "FACETS_USER_KUBECONFIG"
                value = "$(params.FACETS_USER_KUBECONFIG)"
              }
            ]
          }
        ], local.steps_with_k8s_env)
      },
      {
        params = concat(
          [
            {
              name = "FACETS_USER_EMAIL"
              type = "string"
            }
          ],
          var.params
        )
      }
    )
  }

  resources_data = [local.stepaction_data, local.task_data]
}
