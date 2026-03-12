variable "instance" {
  type    = any
  default = {}
}

variable "instance_name" {
  type    = string
  default = ""
}

variable "environment" {
  type    = any
  default = {}
}

variable "inputs" {
  type        = any
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
