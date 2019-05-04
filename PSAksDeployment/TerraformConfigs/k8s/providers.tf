provider "kubernetes" {
  # Preventing automatic upgrades to new versions that may contain breaking changes.
  # Any non-beta version >= 1.6.0 and < 2.0.0
  version = "~>1.6"
}

provider "null" {
  version = "~>2.1"
}

provider "helm" {
  version = "~>0.9"
}

provider "template" {
  version = "~>2.1"
}

provider "local" {
  version = "~>1.2"
}

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
