module "tekton_resources" {
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"
  namespace       = local.namespace
  advanced_config = {}
  name            = module.workflow_helm_name.name
  resources_data  = local.resources_data
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
