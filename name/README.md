# Terraform Module Name

This Terraform module generates the name of the resource being managed by a Facets control plane, ensuring that it follows Facets naming conventions.

## Usage

To use this module, you can include it in your Terraform configuration as follows:

```hcl
module "resource_name" {
  source = "./name"

  # Required variables
  resource_name = "my_resource"
  resource_type = "example_resource"
  environment   = {
    name        = "example-name"
    cluster_code = "abc01"  # Any alphabetic code in lowercase
    unique_name = "unique-name"
  }
  limit         = 25
  is_k8s       = false
  globally_unique = false
  prefix        = "my-prefix-"
}
```

## Variables

| Name              | Description                                                                                                         | Type    | Default | Required |
|-------------------|---------------------------------------------------------------------------------------------------------------------|---------|---------|----------|
| `resource_type`   | Resource type to be used while generating the name                                                                  | string  | n/a     | yes      |
| `resource_name`   | Resource name to be used while generating the name                                                                  | string  | n/a     | yes      |
| `is_k8s`         | Boolean flag to determine whether the resource is getting deployed in k8s or not.                                   | bool    | false   | no       |
| `limit`          | The maximum limit of the resource name to be generated.                                                             | number  | n/a     | yes      |
| `environment`     | Environment configuration. A dictionary containing elements such as name, cluster_code (in lowercase), and unique_name.         | any     | n/a     | yes      |
| `globally_unique` | Optional flag to determine whether the resource name to be generated has to be globally unique across any cloud.    | bool    | false   | no       |
| `prefix`          | Optional flag to pass any prefix to the resource name generated. Useful if the generated name contains an integer at the beginning. | string  | ""     | no       |
