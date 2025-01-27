variable "resource_type" {
  type = string
  description = "Resource type to be used while generating the name. This will generally be the intent name."
}

variable "resource_name" {
  type = string
  description = "Resource name to be used while generating the name."
}

variable "is_k8s" {
  type = bool
  default = false
  description = "Boolean flag to determine whether the resource is getting deployed in Kubernetes. If false, the generated name will not contain the project name."
}

variable "limit" {
  type = number
  description = "The maximum limit for the resource name to be generated. If the generated name exceeds the limit, hashing techniques will be used to reduce the character count."
}

variable "environment" {
  type = any
  description = "Environment configuration. Pass the entire environment variable to the module to generate the name."
}

variable "globally_unique" {
  type = bool
  default = false
  description = "Optional flag to determine whether the generated resource name needs to be globally unique across all clouds."
}

variable "prefix" {
  type = string
  default = ""
  description = "Optional flag to pass any prefix to the resource name. Useful if the generated name contains a number at the beginning, which may not comply with naming conventions."
}