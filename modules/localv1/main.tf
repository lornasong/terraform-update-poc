resource "local_file" "old_file" {
    for_each = var.services
    content = each.value.address
    filename = "resources/${each.value.name}.old"
}

resource "local_file" "same_file" {
    for_each = var.services
    content = each.value.address
    filename = "resources/${each.value.name}.same"
}

resource "local_file" "diff_file" {
    for_each = var.services
    content = each.value.address
    filename = "resources/${each.value.name}-v1.diff"
}
