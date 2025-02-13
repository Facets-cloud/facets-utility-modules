variable "iam_arns" {
  type = any
}

variable "iam_role_name" {
  type = string 
}

variable "namespace" {
  type = string 
}

variable "sa_name" {
  type = string 
}

variable "eks_oidc_provider_arn" {
  type = string
}