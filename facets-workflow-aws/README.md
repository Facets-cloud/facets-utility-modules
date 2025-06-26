# Facets Workflow AWS Module

This Terraform module creates Tekton `Task` and `StepAction` resources for executing AWS workflows. It automatically sets up AWS authentication via IAM role assumption and provides a framework for defining custom workflow steps that can interact with AWS services.

## Features

- Automatically configures AWS authentication
- Creates Tekton `Task` with custom steps
- Supports custom parameters and environment variables
- Injects AWS credentials into all workflow steps

## Inputs

### Required Variables

- `name` (string, required): Function name of the workflow (e.g., "backup-rds", "scale-ec2", "deploy-lambda").
- `steps` (list, required): List of step objects with fields: `name`, `image`, `script`, `resources`, `env`.
- `account_id` (string, required): AWS Account ID for the workflow operations. Typically: `var.inputs.cloud_account.attributes.account_id`.

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
module "restart_task" {
  source     = "github.com/Facets-cloud/facets-utility-modules//facets-workflow-aws"
  name       = "vm-restart"

  instance_name = var.instance_name
  environment   = var.environment
  instance      = var.instance
  providers = {
    helm = "helm.release-pod"
  }

  account_id = var.inputs.cloud_account.attributes.account_id
  params = [
    {
      name        = "ACTION"
      type        = "string"
      description = "supported actions: restart, stop, start"
    }
  ]
  steps = [
    {
      name      = "restart-instance"
      image     = "mikesir87/aws-cli:latest"
      resources = {}
      env = [
        {
          name  = "AWS_REGION"
          value = substr(aws_instance.this.availability_zone, 0, length(aws_instance.this.availability_zone) - 1)
        },
        {
          name  = "INSTANCE_ID"
          value = aws_instance.this.id
        }
      ]
      script = <<-EOT
        #!/bin/bash
        echo "Starting EC2 instance action workflow..."
        echo "Instance ID: $INSTANCE_ID"
        echo "Region: $AWS_REGION"
        echo "Action: $(params.ACTION)"
        
        # Verify instance exists
        aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
        if [ $? -ne 0 ]; then
          echo "Error: Instance $INSTANCE_ID not found or not accessible."
          exit 1
        fi
        
        # Get current state
        INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $AWS_REGION --query 'Reservations[0].Instances[0].State.Name' --output text)
        echo "Current instance state: $INSTANCE_STATE"
        
        case "$(params.ACTION)" in
          restart)
            echo "Restarting instance $INSTANCE_ID..."
            aws ec2 reboot-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
            if [ $? -eq 0 ]; then
              echo "Restart command sent successfully."
              echo "Waiting for instance to complete restart..."
              aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID --region $AWS_REGION
              echo "Instance restart completed successfully."
            else
              echo "Failed to restart instance."
              exit 1
            fi
            ;;
          stop)
            if [ "$INSTANCE_STATE" != "running" ]; then
              echo "Instance is not in 'running' state. Current state: $INSTANCE_STATE. Skipping stop."
              exit 0
            fi
            echo "Stopping instance $INSTANCE_ID..."
            aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
            if [ $? -eq 0 ]; then
              echo "Stop command sent successfully."
              echo "Waiting for instance to stop..."
              aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID --region $AWS_REGION
              echo "Instance stopped successfully."
            else
              echo "Failed to stop instance."
              exit 1
            fi
            ;;
          start)
            if [ "$INSTANCE_STATE" != "stopped" ]; then
              echo "Instance is not in 'stopped' state. Current state: $INSTANCE_STATE. Skipping start."
              exit 0
            fi
            echo "Starting instance $INSTANCE_ID..."
            aws ec2 start-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
            if [ $? -eq 0 ]; then
              echo "Start command sent successfully."
              echo "Waiting for instance to start..."
              aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $AWS_REGION
              echo "Instance started successfully."
            else
              echo "Failed to start instance."
              exit 1
            fi
            ;;
          *)
            echo "Invalid ACTION: $(params.ACTION). Supported actions: start, stop, restart."
            exit 1
            ;;
        esac
      EOT
    }
  ]
}
```

## Output

This module creates:
- A Tekton `StepAction` that sets up AWS authentication via IAM role assumption
- A Tekton `Task` with the specified steps that can interact with AWS services
- Automatic injection of AWS credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) into all workflow steps

## Authentication

The module automatically handles AWS authentication by:
1. Retrieving cloud account credentials from AWS Secrets Manager
2. Assuming the appropriate IAM role using external ID
3. Creating temporary AWS credentials for the workflow
4. Making AWS CLI commands available to all workflow steps with proper authentication 