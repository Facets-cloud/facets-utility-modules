variable "resource_type" {
  type = string
  description = "Resource type to be used while generating the name"
}

variable "resource_name" {
  type = string
  description = "Resource name to be used while generating the name"
}

variable "is_k8s" {
  type = bool
  default = false
  description = "Boolean flag to determine whether the resource is getting deployed in k8s or not. In case this is false, then the generated name will not have the project name within it."
}

variable "limit" {
  type = number
  description = "The maximum limit of the resource name to be generated. In case, if the generated name exceeds the limits, then a few hashing techniques will be used to reduce the character limit of the name."
}

variable "environment" {
  type = any
  description = "Environment configuration. Pass the entire environment variable to the module to generate the name."
}

variable "globally_unique" {
  type = bool
  default = false
  description = "Optional flag to determine whether the resource name to be generated has to be globally unique across any cloud."
}

variable "prefix" {
  type = string
  default = ""
  description = "Optional flag to pass any prefix to the resource name generated. Useful in the cases if the generated name contains a integer in the beginning, and the naming convention does not allow any numeric value in the beginning."
}