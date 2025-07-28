# Tekton Task Utility Module

This Terraform module abstracts the creation of Tekton `Task.tekton.dev/v1beta1` resources. It allows you to define steps and params as input variables, so you don't need to manually configure the Kubernetes manifest.

## Inputs

- `name` (string, required): Name of the Tekton Task.
- `namespace` (string, optional): Namespace for the Task. Default: `tekton-pipelines`.
- `steps` (list, required): List of step objects (fields: `name`, `image`, `script`, etc.).
- `params` (list, optional): List of param objects (fields: `name`, `type`, `default`, etc.).

## Example Usage

```hcl
module "restart_task" {
  # Mandatory fields (dont changet the values)
  source     = "github.com/Facets-cloud/facets-utility-modules//facets-workflows/aws"
  instance_name = var.instance_name
  environment   = var.environment
  instance      = var.instance
  providers = {
    helm = "helm.release-pod"
  }
  account_id = var.inputs.cloud_account.attributes.account_id


  # Following fiels should be configured accorind to the usecase
  name       = "vm-restart"
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

Creates a Tekton Task with the specified steps and params. 