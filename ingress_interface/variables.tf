variable "rules" {
  type        = any
  description = "The rules attribute in spec"
}

variable "domains" {
  type        = any
  description = "The domains attribute in spec"
}

variable "username" {
  type        = string
  description = "The username"
  default     = ""
}

variable "password" {
  type        = string
  description = "The password"
  default     = ""
}
