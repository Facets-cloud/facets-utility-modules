# Facets Workflow Kubernetes Module

This Terraform module creates Tekton `Task` and `StepAction` resources for executing Kubernetes workflows. It automatically sets up Kubernetes authentication and provides a framework for defining custom workflow steps that can interact with Kubernetes clusters.

## Features

- Automatically configures Kubernetes authentication
- Creates Tekton `Task` with custom steps
- Supports custom parameters and environment variables

## Inputs

### Required Variables

- `name` (string, required): Function name of the workflow (e.g., "rollout-restart", "scale-deployment").
- `steps` (list, required): List of step objects with fields: `name`, `image`, `script`, `resources`, `env`.

### Standard Facets Variables (Required - Do Not Change)

These variables are constant and should always be provided with the exact values shown below:

- `instance_name = var.instance_name` (string): Name of the Facets instance
- `environment = var.environment` (object): Facets environment configuration  
- `instance = var.instance` (object): Facets instance configuration

**Important**: The values for these variables must always be `var.instance_name`, `var.environment`, and `var.instance` respectively. Do not change these values.

### Optional Variables

- `namespace` (string, optional): Namespace for the Tekton resources. Default: `"tekton-pipelines"`.
- `params` (list, optional): List of param objects for the Tekton Task. Default: `[]`.

## Provider Configuration (Required - Do Not Change)

```hcl
providers = {
  helm = "helm.release-pod"
}
```

## Example Usage

```hcl
module "rollout_restart_task" {
  source     = "github.com/Facets-cloud/facets-utility-modules//facets-workflow-kubernetes"
  name       = "rollout-restart"
  namespace  = local.namespace

  instance_name = var.instance_name
  environment   = var.environment
  instance      = var.instance
  providers = {
    helm = "helm.release-pod"
  }

  steps = [
    {
      name      = "restart-deployments"
      image     = "bitnami/kubectl:latest"
      resources = {}
      env = [
        {
          name  = "RESOURCE_TYPE"
          value = local.resource_type
        },
        {
          name  = "RESOURCE_NAME"
          value = local.resource_name
        },
        {
          name  = "NAMESPACE"
          value = local.namespace
        }
      ]
      script = <<-EOT
        #!/bin/bash
        set -e
        echo "Starting Kubernetes deployment rollout restart workflow..."
        echo "Resource Type: $RESOURCE_TYPE"
        echo "Resource Name: $RESOURCE_NAME"
        
        # Define label selector
        LABEL_SELECTOR="resourceType=$RESOURCE_TYPE,resourceName=$RESOURCE_NAME"
        echo "Label selector: $LABEL_SELECTOR"
        
        # Find deployments with matching labels
        DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE -l "$LABEL_SELECTOR" -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')
        
        if [ -z "$DEPLOYMENTS" ]; then
          echo "No deployments found with labels: $LABEL_SELECTOR"
          exit 0
        fi
        
        echo "Found deployments:"
        echo "$DEPLOYMENTS"
        
        echo "Performing rollout restart for deployments..."
        while IFS= read -r deployment; do
          if [ -n "$deployment" ]; then
            namespace=$NAMESPACE
            name=$(echo "$deployment" | cut -d'/' -f2)
            echo "Restarting deployment: $name in namespace: $namespace"
            
            kubectl rollout restart deployment "$name" -n "$namespace"
            if [ $? -eq 0 ]; then
              echo "Rollout restart initiated for $name"
              echo "Waiting for rollout to complete..."
              kubectl rollout status deployment "$name" -n "$namespace" --timeout=300s
              if [ $? -eq 0 ]; then
                echo "Rollout completed successfully for $name"
              else
                echo "Rollout timeout or failed for $name"
                exit 1
              fi
            else
              echo "Failed to initiate rollout restart for $name"
              exit 1
            fi
          fi
        done <<< "$DEPLOYMENTS"
        echo "All deployments restarted successfully."
      EOT
    }
  ]
}
```

## Output

This module creates:
- A Tekton `StepAction` that sets up Kubernetes authentication
- A Tekton `Task` with the specified steps that can interact with the Kubernetes cluster
- Automatic injection of `KUBECONFIG` environment variable for kubectl access

## Authentication

The module automatically handles Kubernetes authentication