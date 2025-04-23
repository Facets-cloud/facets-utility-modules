resource "kubernetes_job" "postgres-database" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }
  spec {
    template {
      metadata {
        name = var.name
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres"
          env {
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_secret.metadata[0].name
                key  = "password"
              }
            }
          }
          security_context {
            allow_privilege_escalation = false
            run_as_non_root            = true
            run_as_user                = 1000
            run_as_group               = 1000
          }
          command = [
            "bash",
            "-c",
            <<-EOF
            for db_name in ${join(" ", local.db_names)}; do
              if psql -h ${var.host} -U ${var.username} -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$db_name'" | grep -q 1; then
                echo "Skipping $db_name as it already exists."
              else
                echo "Creating database: $db_name"
                psql -h ${var.host} -U ${var.username} -d postgres -c "CREATE DATABASE \"$db_name\";"
              fi
            done

            db_schemas_str="${local.db_schema_str}"
            IFS=';' read -ra db_schemas <<< "$db_schemas_str"
            for db_schema in "$${db_schemas[@]}"; do
              IFS='=' read -ra db_schema_split <<< "$db_schema"
              db_name=$${db_schema_split[0]}
              IFS=',' read -ra schemas <<< "$${db_schema_split[1]}"
              for schema in "$${schemas[@]}"; do
                  schema_exists=$(psql -h ${var.host} -U ${var.username} -d "$db_name" -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name = '$schema'")
                  if [ "$schema_exists" = "1" ]; then
                      echo "Schema $schema exists in database $db_name, skipping creation"
                  else
                      echo "Creating schema: $schema in database: $db_name"
                      psql -h ${var.host} -U ${var.username} -d "$db_name" -c "CREATE SCHEMA \"$schema\";"
                  fi
              done
            done
            EOF
          ]
        }
        dynamic "toleration" {
          for_each = concat(var.environment.default_tolerations, var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_tolerations, var.tolerations)
          content {
            key      = lookup(toleration.value, "key", null)
            operator = lookup(toleration.value, "operator", "Equal")
            value    = lookup(toleration.value, "value", null)
            effect   = lookup(toleration.value, "effect", null)
          }
        }
      }
    }
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
    update = "5m"
  }
}

resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret-${var.name}"
    namespace = var.namespace
  }
  data = {
    password = var.password
  }
}