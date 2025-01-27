# Terraform Module Name

This Terraform module generates the name of the resource being managed by a Facets control plane, ensuring that it follows Facets naming conventions.

## Usage

To use this module, you can include it in your Terraform configuration as follows:

```hcl
module "resource_name" {
  source = "https://github.com/Facets-cloud/facets-utility-modules.git//name"

  # Required variables
  resource_name = "my_resource"
  resource_type = "example_resource"
  environment   = var.environment
  limit         = 25
  is_k8s       = false
  
  # Optional variables
  globally_unique = false
  prefix        = "my-prefix-";
}
```

## Variables

| Name              | Description                                                                                                         | Type    | Default | Required |
|-------------------|---------------------------------------------------------------------------------------------------------------------|---------|---------|----------|
| `resource_type`   | Resource type to be used while generating the name. This will generally be the intent name.                         | string  | n/a     | yes      |
| `resource_name`   | Resource name to be used while generating the name.                                                                | string  | n/a     | yes      |
| `is_k8s`         | Boolean flag to determine whether the resource is getting deployed in Kubernetes. If false, the generated name will not contain the project name. | bool    | false   | no       |
| `limit`          | The maximum limit for the resource name to be generated. If the generated name exceeds the limit, hashing techniques will be used to reduce the character count.  | number  | n/a     | yes      |
| `environment`     | Environment configuration. Pass the entire environment variable to the module to generate the name.                | any     | n/a     | yes      |
| `globally_unique` | Optional flag to determine whether the generated resource name needs to be globally unique across all clouds.       | bool    | false   | no       |
| `prefix`          | Optional flag to pass any prefix to the resource name. Useful if the generated name contains a number at the beginning, which may not comply with naming conventions. | string  | ""     | no       |
