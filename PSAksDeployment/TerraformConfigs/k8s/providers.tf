provider "kubernetes" {
  # Preventing automatic upgrades to new versions that may contain breaking changes.
  # Any non-beta version >= 1.5.0 and < 2.0.0
  version = "~>1.5"
}

provider "null" {
  version = "~>1.0"
}

provider "helm" {
  version = "~>0.8"
}

provider "template" {
  version = "~>1.0"
}

provider "local" {
  version = "~>1.1"
}

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
