variable "name" {
  description = "Name of the Tekton Task."
  type        = string
}

variable "description" {
  description = "Description of the Tekton Task."
  type        = string
  default     = ""
}

variable "steps" {
  description = "List of steps for the Tekton Task."
  type = list(object({
    name      = string
    image     = string
    resources = any
    script    = string
    env       = list(object({
      name  = string
      value = string
    }))
  }))
  default = []
}

variable "params" {
  description = "List of params for the Tekton Task."
  type        = any
  default     = []
}

variable "instance_name" {
  type    = string
}

variable "environment" {
  type = any
}

variable "instance" {
  type = any
}

variable "auth_secret_name" {
  type = string
  default = "var.inputs.kubernetes_details.attributes.legacy_outputs.k8s_details.workflows_auth_secret_name"
}