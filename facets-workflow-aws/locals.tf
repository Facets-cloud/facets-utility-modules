locals {
  deployment_context       = jsondecode(file("/sources/primary/capillary-cloud-tf/deploymentcontext.json"))
  secrets_context          = lookup(local.deployment_context, "secretsContext", {})
  secret_manager_region    = lookup(local.secrets_context, "secretManagerRegion", null)
  cloud_account_secrets_id = lookup(local.secrets_context, "cloudAccountSecretsId", null)
  cp_cloud                 = lookup(local.secrets_context, "cpCloud", null)
  cp_name                  = split("/", local.cloud_account_secrets_id)[0]

  name = "${var.instance_name}-${var.environment.unique_name}-${var.name}"

  labels = {
    resource_name    = var.instance_name
    resource_kind    = var.instance.kind
    resource_flavor  = var.instance.flavor
    resource_version = var.instance.version
    cluster_code     = var.environment.cluster_code
    environment      = var.environment.unique_name
  }

  aws_init_commands = <<-EOT
    #!/bin/bash
    set -e
    SECRET=$(aws secretsmanager get-secret-value --secret-id "${local.cloud_account_secrets_id}" --region "${local.secret_manager_region}" --query SecretString --output text)
    echo "Extract externalId using grep and sed"
    EXTERNAL_ID=$(echo $SECRET | jq -r .externalId)
    IAM_ROLE=$(echo $SECRET | jq -r .iamRole)
    
    CREDS=$(aws sts assume-role --role-arn $IAM_ROLE --role-session-name "${var.name}" --external-id $EXTERNAL_ID)
    
    echo "Writing credentials to shared file..."
    mkdir -p /workspace/.aws
    chmod 600 /workspace/.aws
    echo "[default]" > /workspace/.aws/credentials
    ACCESS_KEY_ID=$(echo $CREDS | jq -r .Credentials.AccessKeyId)
    echo "aws_access_key_id=$ACCESS_KEY_ID" >> /workspace/.aws/credentials
    SECRET_ACCESS_KEY=$(echo $CREDS | jq -r .Credentials.SecretAccessKey)
    echo "aws_secret_access_key=$SECRET_ACCESS_KEY" >> /workspace/.aws/credentials
    SESSION_TOKEN=$(echo $CREDS | jq -r .Credentials.SessionToken)
    echo "aws_session_token=$SESSION_TOKEN" >> /workspace/.aws/credentials
    echo "[default]" > /workspace/.aws/config
    chmod 600 /workspace/.aws/config
    echo "region=${local.secret_manager_region}" >> /workspace/.aws/config
    # Write credentials to results
    echo -n $ACCESS_KEY_ID > $(step.results.AWS_ACCESS_KEY_ID.path)
    echo -n $SECRET_ACCESS_KEY > $(step.results.AWS_SECRET_ACCESS_KEY.path)
    echo -n $SESSION_TOKEN > $(step.results.AWS_SESSION_TOKEN.path)
  EOT

  steps_with_aws_env = [
    for step in var.steps : merge(
      step,
      {
        env = concat(
          lookup(step, "env", []),
          [
            {
              name  = "AWS_ACCESS_KEY_ID"
              value = "$(steps.setup-credentials.results.AWS_ACCESS_KEY_ID)"
            },
            {
              name  = "AWS_SECRET_ACCESS_KEY"
              value = "$(steps.setup-credentials.results.AWS_SECRET_ACCESS_KEY)"
            },
            {
              name  = "AWS_SESSION_TOKEN"
              value = "$(steps.setup-credentials.results.AWS_SESSION_TOKEN)"
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
      namespace = var.namespace
      labels = local.labels
    }
    spec = {
      image = "mikesir87/aws-cli:latest"
      results = [
        {
          name : "AWS_ACCESS_KEY_ID"
          description : "AWS access key ID"
        },
        {
          name : "AWS_SECRET_ACCESS_KEY"
          description : "AWS secret access key"
        },
        {
          name : "AWS_SESSION_TOKEN"
          description : "AWS session token"
        }
      ]
      script = local.aws_init_commands
    }
  }

  task_data = {
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = module.task_name.name
      namespace = var.namespace
      labels = local.labels
    }
    spec = merge(
      {
        steps = concat([
          {
            name = "setup-credentials"
            ref = {
              name = module.stepaction_name.name
            }
          }
        ], local.steps_with_aws_env)
      },
      length(var.params) > 0 ? { params = var.params } : {}
    )
  }

  resources_data = [local.stepaction_data, local.task_data]
}
