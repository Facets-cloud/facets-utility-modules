# Deep Merge Terraform Module

This Terraform module deeply merges two input variables, `left` and `right`, using the `jq` tool to ensure comprehensive and accurate merging of complex data structures.

## Usage

To use this module, include it in your Terraform configuration as follows:

```hcl
module "deep_merge" {
  source = "github.com/Facets-cloud/facets-utility-modules//deepmerge"

  # Required variables
  left  = var.left
  right = var.right
}
```

## Variables

| Name              | Description                                                                                                                                                                   | Type | Default | Required |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------|---------|----------|
| `left`            | The value that needs to be merged with the other variable.                                                                                                                   | any  | n/a     | yes      |
| `right`           | The value that needs to be merged with the other variable.                                                                                                                   | any  | n/a     | yes      |

## Outputs

| Name         | Description                                        |
|--------------|----------------------------------------------------|
| `deepmerged` | The result of the deep merge operation.            |
