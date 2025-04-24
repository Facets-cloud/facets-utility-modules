locals {
  db_names      = distinct(concat(var.db_names, [for _, value in var.db_schemas : value.db]))
  db_schema_map = { for key, value in var.db_schemas : value.db => value.schema... }
  db_schema_str = join(";", [for db_name, schemas in local.db_schema_map : "${db_name}=${join(",", schemas)}"])
}
