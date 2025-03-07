data "external" "merge" {
  program = [
    "/usr/bin/jq",
    "((.left|fromjson) * (.right|fromjson))|with_entries(.value|=tojson)"
  ]
  query = {
    left  = jsonencode(var.left)
    right = jsonencode(var.right)
  }
}
