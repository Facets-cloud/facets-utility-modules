# Protected Kubernetes Resource Module

## Overview

This module deploys Kubernetes resources dynamically using Helm with **lifecycle protection** (`prevent_destroy = true`). It is specifically designed for critical, stateful resources where accidental destruction could result in data loss.

## Key Feature

⚠️ **Destruction Prevention**: This module includes a hardcoded `prevent_destroy = true` lifecycle block that prevents accidental resource deletion via `terraform destroy`.

## When to Use

Use this module for:
- **Databases** (PostgreSQL, MySQL, MongoDB, etc.)
- **Datastores** (Redis, Elasticsearch, Cassandra, etc.)
- **Stateful resources** where data persistence is critical
- **Custom Resources** that manage persistent data

## When NOT to Use

For non-critical resources, use the standard `any-k8s-resource` module instead:
- ConfigMaps
- Secrets (non-critical)
- Deployments without persistent data
- Services
- Ingress resources

## Usage

```hcl
module "database_resource" {
  source = "github.com/Facets-cloud/facets-utility-modules//protected-k8s-resource"

  name      = "my-database"
  namespace = "production"

  advanced_config = {
    timeout         = 600
    cleanup_on_fail = true
    wait            = true
  }

  data = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      labels = {
        app = "my-database"
      }
    }
    spec = {
      instances = 3
      storage = {
        size = "100Gi"
      }
    }
  }
}
```

## Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | Yes | - | Name of the Kubernetes resource |
| `namespace` | string | Yes | - | Kubernetes namespace for deployment |
| `data` | any | Yes | - | Kubernetes resource manifest as HCL object |
| `advanced_config` | any | No | See below | Helm release configuration options |
| `release_name` | string | No | `null` | Custom Helm release name (defaults to `name`) |

### Advanced Config Options

```hcl
advanced_config = {
  timeout         = 300    # Helm operation timeout in seconds
  cleanup_on_fail = true   # Cleanup resources on failed installation
  wait            = false  # Wait for resources to be ready
  max_history     = 10     # Maximum number of release revisions
}
```

## Lifecycle Protection

### What is Protected?

The `helm_release` resource is protected from destruction. When attempting to destroy:

```bash
terraform destroy
```

You will receive an error:

```
Error: Instance cannot be destroyed

Resource helm_release.k8s-resource has lifecycle.prevent_destroy set,
but the plan calls for this resource to be destroyed.
```

### How to Remove Protected Resources

If you genuinely need to destroy a protected resource:

1. **Option A: Remove lifecycle protection**
   - Edit `main.tf` in the module
   - Remove or comment out the `lifecycle` block
   - Run `terraform apply` then `terraform destroy`

2. **Option B: Use -replace flag**
   ```bash
   terraform destroy -replace="module.database_resource.helm_release.k8s-resource"
   ```

3. **Option C: Remove from state**
   ```bash
   terraform state rm module.database_resource.helm_release.k8s-resource
   # Then manually delete the Kubernetes resource
   ```

## Differences from `any-k8s-resource`

| Feature | `any-k8s-resource` | `protected-k8s-resource` |
|---------|-------------------|-------------------------|
| Lifecycle protection | ❌ None | ✅ `prevent_destroy = true` |
| Use case | General resources | Critical/stateful resources |
| Destruction | Allowed | Blocked |

## Important Notes

1. **Not overridable**: The lifecycle protection cannot be disabled via variables - this is intentional to prevent accidental bypasses
2. **Applies to Helm release**: Protection applies to the Helm release resource, not individual Kubernetes objects within the release
3. **Module choice is intentional**: Using this module vs `any-k8s-resource` should be a deliberate architectural decision

## Resources Created

- `helm_release.k8s-resource` - Helm release with lifecycle protection

## Helm Chart

Uses the embedded `dynamic-k8s-resource-0.1.0.tgz` Helm chart to deploy arbitrary Kubernetes resources.
