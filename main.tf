terraform {
    required_version = ">=0.13"
}

module "local" {
    source = "./modules/localv1"
    services = var.services
}
