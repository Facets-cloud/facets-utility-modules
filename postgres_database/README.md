# Postgres Database Terraform Module

This Terraform module creates a Kubernetes job that creates PostgreSQL databases and schemas. The job uses the official PostgreSQL image to execute database and schema creation commands.

## Usage

```hcl
module "postgres_database" {
  source = "github.com/Facets-cloud/facets-utility-modules//postgres_database"

  name      = "my-postgres-db"
  namespace = "default"
  
  # Database configuration
  db_names    = ["db1", "db2"]
  db_schemas  = {
    schema1 = {
      db     = "db1"
      schema = "schema1"
    }
    schema2 = {
      db     = "db2"
      schema = "schema2"
    }
  }

  # Connection details
  host     = "postgres-host"
  username = "postgres-user"
  password = "postgres-password"

  # Kubernetes configuration
  environment = var.environment
  inputs      = var.inputs
  
  # Optional: Add custom tolerations
  tolerations = [
    {
      key      = "example-key"
      operator = "Equal"
      value    = "example-value"
      effect   = "NoSchedule"
    }
  ]
}
```

## Features

- Creates multiple PostgreSQL databases
- Creates multiple schemas within specified databases
- Skips creation if database/schema already exists
- Runs as a Kubernetes job with proper security context
- Supports custom tolerations
- Stores database password in a Kubernetes secret

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name for the Kubernetes resources | `string` | n/a | yes |
| `namespace` | Kubernetes namespace | `string` | n/a | yes |
| `db_names` | List of database names to create | `list(string)` | n/a | yes |
| `db_schemas` | Map of schema configurations | `map(object({db = string, schema = string}))` | `{}` | no |
| `username` | PostgreSQL username | `string` | n/a | yes |
| `host` | PostgreSQL host | `string` | n/a | yes |
| `password` | PostgreSQL password | `string` | n/a | yes |
| `tolerations` | List of Kubernetes tolerations to be applied to the database creation job | `list(object({key = string, operator = string, value = string, effect = string}))` | `[]` | no |
| `environment` | Environment configuration | `any` | n/a | yes |
| `inputs` | Input configuration | `any` | n/a | yes |

## Security Features

- Runs as non-root user (UID 1000)
- Disables privilege escalation
- Stores password in Kubernetes secret

## Job Behavior

- Waits for completion (timeout: 5 minutes)
- Checks for existing databases/schemas before creation
- Uses secure environment variables for credentials
