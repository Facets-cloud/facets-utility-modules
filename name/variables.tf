variable "resource_type" {
  type = string
}

variable "resource_name" {
  type = string
}

variable "is_k8s" {
  type = bool
  default = false
}

variable "limit" {
  type = number
}

variable "environment" {
  type = any
}

variable "globally_unique" {
  type = bool
  default = false
}

variable "prefix" {
  type = string
  default = ""
}