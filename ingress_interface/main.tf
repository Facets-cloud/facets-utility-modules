locals {
  is_auth_enabled = length(var.username) > 0 && length(var.password) > 0 ? true : false
  inside_rules = [for domain_key, domain in var.domains : {
    for rule_key, rule in lookup(domain, "rules", {}) : domain_key == "defaultBase" ? "facets_${rule_key}" : "${domain_key}_${rule_key}" => {
      host = length(lookup(rule, "domain_prefix", {})) > 0 ? "${rule.domain_prefix}.${domain.domain}" : "${domain.domain}"
    } if rule.service_name != ""
  }]

  outside_rules = [for domain_key, domain in var.domains : {
    for rule_key, rule in var.rules : domain_key == "defaultBase" ? "facets_${rule_key}" : "${domain_key}_${rule_key}" => {
      host = length(lookup(rule, "domain_prefix", {})) > 0 ? "${rule.domain_prefix}.${domain.domain}" : "${domain.domain}"
    } if rule.service_name != ""
  }]

  merge_concat_rules = merge(concat(local.inside_rules, local.outside_rules)...)

  interfaces = {
    for rule_key, rule in local.merge_concat_rules : rule_key => {
      connection_string = local.is_auth_enabled ? "https://${var.username}:${var.password}@${rule.host}:443" : "https://${rule.host}:443"
      host              = rule.host
      port              = 443
      username          = var.username
      password          = var.password
      secrets           = local.is_auth_enabled ? ["connection_string", "password"] : []
    }
  }
}
