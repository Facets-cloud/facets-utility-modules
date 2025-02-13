

module "iam_eks_role" {
  source           = "./iam-role-for-service-accounts-eks"
  role_name        = var.iam_role_name
  role_policy_arns = { for k, v in var.iam_arns : k => v.arn }
  oidc_providers = {
    one = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${var.sa_name}"]
    }
  }
}

output "iam_role_arn" {
  value = module.iam_eks_role.iam_role_arn
}
