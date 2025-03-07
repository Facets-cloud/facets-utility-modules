output "deepmerged" {
  value = {
    for k, v in data.external.merge.result : k => jsondecode(v)
  }
}
