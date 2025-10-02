terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.0"
    }
  }
}

provider "auth0" {
  domain        = var.auth0_domain
  client_id     = var.auth0_client_id
  client_secret = var.auth0_client_secret
}

# Basic Auth0 Tenant - just the essentials
resource "auth0_tenant" "main" {
  friendly_name = "tes"
}

