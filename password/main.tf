resource "random_password" "password" {
  length           = var.length
  override_special = var.override_special
  special          = var.special
  lifecycle {
    ignore_changes = [
      length,
      override_special,
      special
    ]
  }
}