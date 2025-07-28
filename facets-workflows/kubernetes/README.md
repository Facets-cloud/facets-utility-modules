# Tekton Task Utility Module

This Terraform module abstracts the creation of Tekton `Task.tekton.dev/v1beta1` resources. It allows you to define steps and params as input variables, so you don't need to manually configure the Kubernetes manifest.

## Inputs

- `name` (string, required): Name of the Tekton Task.
- `namespace` (string, optional): Namespace for the Task. Default: `tekton-pipelines`.
- `steps` (list, required): List of step objects (fields: `name`, `image`, `script`, etc.).
- `params` (list, optional): List of param objects (fields: `name`, `type`, `default`, etc.).

## Example Usage
create following `tekton.tf` file in the facets module
```hcl
module "rollout_restart_task" {
  # Mandatory fields (dont changet the values)
  source     = "github.com/Facets-cloud/facets-utility-modules//facets-workflows/aws"
  instance_name = var.instance_name
  environment   = var.environment
  instance      = var.instance
  auth_secret_name = var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.workflows_auth_secret_name
  providers = {
    helm = "helm.release-pod"
  }

  # Following fiels should be configured accorind to the usecase
  name       = "rollout-restart"
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

Creates a Tekton Task with the specified steps and params. 