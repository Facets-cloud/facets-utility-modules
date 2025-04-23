variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "db_names" {
  type = list(string)
}

variable "db_schemas" {
  type = map(object({
    db     = string
    schema = string
  }))
  default = {}
}

variable "username" {
  type = string
}

variable "host" {
  type = string
}

variable "password" {
  type = string
}

variable "tolerations" {
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}

variable "environment" {
  type = any
}

variable "inputs" {
  type = any
}
