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
    kubernetes_details = optional(object({
      cloud_provider = optional(string)
    }))
    kubernetes_node_pool_details = optional(any)
    artifactories                = optional(any)
    cert_manager_details         = optional(any)
    gateway_api_crd_details = object({
      attributes = object({
        job_name = string
        version  = string
      })
    })
    prometheus_details = optional(any)
  })
  description = "Inputs from other modules. gateway_api_crd_details is required."
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
