variable "length" {
  type    = number
  default = 12
}

variable "override_special" {
  type = string
  default = "$!"
}

variable "special" {
  type = bool
  default = true
}