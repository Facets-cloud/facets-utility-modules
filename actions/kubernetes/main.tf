resource "helm_release" "workflows" {
  provider         = "helm-release-pod"
  name             = module.workflow_helm_name.name
  chart            = "${path.module}/dynamic-k8s-resources-0.1.0.tgz"
  timeout          = 300
  wait             = false
  version          = "0.1.0"
  create_namespace = true
  max_history      = 10
  namespace        = local.namespace
  values = [
    jsonencode({
      resources = local.resources_data
    })
  ]
}

module "workflow_helm_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = true
  globally_unique = false
  resource_name   = local.name
  resource_type   = "workflow"
  limit           = 53
  environment     = var.environment
}

module "stepaction_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = true
  globally_unique = false
  resource_name   = local.name
  resource_type   = "stepaction"
  limit           = 63
  environment     = var.environment
  prefix          = "setup-credentials-"
}

module "task_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = true
  globally_unique = false
  resource_name   = local.name
  resource_type   = "task"
  limit           = 63
  environment     = var.environment
}
