provider "azurerm" {
  # Preventing automatic upgrades to new versions that may contain breaking changes.
  # Any non-beta version >= 1.22.0 and < 2.0.0
  version = "~>1.22"

  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
