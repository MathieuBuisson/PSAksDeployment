provider "kubernetes" {
  # Preventing automatic upgrades to new versions that may contain breaking changes.
  # Any non-beta version >= 1.3.0 and < 2.0.0
  version = "~>1.3"
}

provider "null" {
  version = "~>1.0"
}

provider "helm" {
  version = "~>0.6"
}

provider "template" {
  version = "~>1.0"
}

provider "local" {
  version = "~>1.1"
}

terraform {
  backend "local" {
    path = "D:/a/1/b/TF_psaks-ci-143/StateFiles/k8s.tfstate"
  }
}
