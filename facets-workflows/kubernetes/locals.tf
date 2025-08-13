locals {
  deployment_context           = jsondecode(file("/sources/primary/capillary-cloud-tf/deploymentcontext.json"))
  cluster_id                   = lookup(lookup(local.deployment_context, "cluster", {}), "id")
  secrets_context              = lookup(local.deployment_context, "secretsContext", {})
  secret_manager_region        = lookup(local.secrets_context, "secretManagerRegion", null)
  cloud_account_secrets_id     = lookup(local.secrets_context, "cloudAccountSecretsId", null)
  cloud_account_prefix         = split("/", local.cloud_account_secrets_id)[0]
  k8s_secretmanger_secret_name = var.auth_secret_name

  labels = {
    resource_name    = var.instance_name
    resource_kind    = var.instance.kind
    environment      = var.environment.unique_name
  }

  name = "${var.instance_name}-${var.environment.unique_name}-${var.name}"
  namespace = "tekton-pipelines"

  k8s_init_commands = <<-EOT
    #!/bin/bash
    set -e
    SECRET=$(aws secretsmanager get-secret-value --secret-id "${local.k8s_secretmanger_secret_name}" --region "${local.secret_manager_region}" --query SecretString --output text)
    export K8S_HOST=$(echo $SECRET | jq -r .host)
    export K8S_CA=$(echo $SECRET | jq -r .cluster_ca_certificate | base64 -w 0)
    export K8S_TOKEN=$(echo $SECRET | jq -r .token)

    mkdir -p /workspace/.kube
    touch /workspace/.kube/config
    
    # Create Kubernetes config using yq v4.x syntax
    yq -i '
      .apiVersion = "v1" |
      .kind = "Config" |
      .current-context = "k8s-context" |
      .clusters = [{
        "name": "k8s",
        "cluster": {
          "server": strenv(K8S_HOST),
          "certificate-authority-data": strenv(K8S_CA)
        }
      }] |
      .contexts = [{
        "name": "k8s-context", 
        "context": {
          "cluster": "k8s",
          "user": "k8s-user"
        }
      }] |
      .users = [{
        "name": "k8s-user",
        "user": {
          "token": strenv(K8S_TOKEN)
        }
      }]
    ' /workspace/.kube/config

    export KUBECONFIG=/workspace/.kube/config
  EOT

  steps_with_k8s_env = [
    for step in values(var.steps) : merge(
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
      image = "nixery.dev/shell/awscli2/kubectl/jq/yq-go"
      script = local.k8s_init_commands
    }
  }

  task_data = {
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = module.task_name.name
      namespace = local.namespace
      labels = local.labels
      annotations = {
        "workflow.facets.cloud/serviceaccount" = "workflows-sa"
      }
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
          }
        ], local.steps_with_k8s_env)
      },
      length(var.params) > 0 ? { params = var.params } : {}
    )
  }

  resources_data = [local.stepaction_data, local.task_data]
}
