variable "instance" {
  type        = any
  description = "Facets instance object containing spec with domains, rules, and configuration"

  validation {
    condition     = can(var.instance.spec)
    error_message = "instance must contain a 'spec' attribute"
  }
}

variable "instance_name" {
  type        = string
  description = "Architectural name of the ingress instance"

  validation {
    condition     = length(trimspace(var.instance_name)) > 0
    error_message = "instance_name must be a non-empty string"
  }
}

variable "environment" {
  type        = any
  description = "Environment context (must contain unique_name and namespace)"

  validation {
    condition     = can(var.environment.unique_name) && can(var.environment.namespace)
    error_message = "environment must contain 'unique_name' and 'namespace' attributes"
  }
}

variable "inputs" {
  type = object({
    kubernetes_details = object({
      attributes = object({
        cloud_provider         = optional(string)
        cluster_id             = optional(string)
        cluster_name           = optional(string)
        cluster_location       = optional(string)
        cluster_endpoint       = optional(string)
        lb_service_record_type = optional(string)
      })
      interfaces = optional(object({
        kubernetes = optional(object({
          cluster_ca_certificate = optional(string)
          host                   = optional(string)
        }))
      }))
    })
    kubernetes_node_pool_details = optional(object({
      attributes = optional(object({
        labels        = optional(any)
        taints        = optional(any)
        node_selector = optional(any)
      }))
    }))
    artifactories = optional(object({
      attributes = optional(object({
        registry_secrets_list = optional(any)
      }))
    }))
    cert_manager_details = optional(object({
      attributes = optional(object({
        acme_email          = optional(string)
        cluster_issuer_http = optional(string)
      }))
    }))
    gateway_api_crd_details = object({
      attributes = object({
        version     = optional(string)
        channel     = optional(string)
        install_url = optional(string)
        job_name    = optional(string)
      })
    })
    prometheus_details = optional(object({
      attributes = optional(object({
        alertmanager_url = optional(string)
        helm_release_id  = optional(string)
        prometheus_url   = optional(string)
      }))
      interfaces = optional(object({}))
    }))
  })
  description = "Inputs from other modules"
}

variable "service_annotations" {
  type        = map(string)
  default     = {}
  description = "Cloud-specific annotations for the LoadBalancer service"
}

variable "nginx_proxy_extra_config" {
  type        = any
  default     = {}
  description = "Extra NginxProxy CRD config (e.g. rewriteClientIP for proxy protocol)"
}
