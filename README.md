# PSAksDeployment

[![Build Status](https://dev.azure.com/mathieubuisson/PSAksDeployment/_apis/build/status/MathieuBuisson.PSAksDeployment)](https://dev.azure.com/mathieubuisson/PSAksDeployment/_build/latest?definitionId=12) [![PS Gallery](https://img.shields.io/powershellgallery/v/PSAksDeployment.svg?style=plastic&label=PowerShell%20Gallery&colorB=blue)](https://www.powershellgallery.com/packages/PSAksDeployment/)

Opinionated tooling to automate the deployment (and destruction) of Azure Kubernetes (AKS) clusters.

This PowerShell module wraps/orchestrates :
  - [Terraform](https://www.terraform.io/) configurations
  - [Kubectl](https://kubernetes.io/docs/reference/kubectl) commands
  - [Helm](https://helm.sh/) (a few custom charts and a bunch of releases)
