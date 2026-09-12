terraform {
  required_version = ">= 1.3.0"

  required_providers {
    linode = {
      source  = "linode/linode"
      version = ">= 2.9.0, < 3.0.0"
    }
  }
}

# Export LINODE_TOKEN
provider "linode" {}
