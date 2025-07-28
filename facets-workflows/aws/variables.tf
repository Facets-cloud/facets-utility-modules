variable "name" {
  description = "Name of the Tekton Task."
  type        = string
}


variable "steps" {
  description = "List of steps for the Tekton Task."
  type = list(object({
    name      = string
    image     = string
    resources = any
    script    = string
    env       = list(any)
  }))
}

variable "params" {
  description = "List of params for the Tekton Task."
  type        = list(any)
  default     = []
}

variable "account_id" {
  description = "Account ID for the Tekton Task."
  type        = string
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