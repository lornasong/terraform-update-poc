resource "local_file" "new_file" {
    for_each = var.services
    content = each.value.address
    filename = "resources/${each.value.name}.new"
}

resource "local_file" "same_file" {
    for_each = var.services
    content = each.value.address
    filename = "resources/${each.value.name}.same"
}

resource "local_file" "diff_file" {
    for_each = var.services
    content = each.value.address
    filename = "resources/${each.value.name}-v2.diff"
}
