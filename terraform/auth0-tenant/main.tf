terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.0"
    }
  }
  
  backend "s3" {
    bucket         = "teleport-challenge-terraform-state"
    key            = "auth0-tenant/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    use_lockfile   = true
  }
}

provider "auth0" {
  domain        = var.auth0_domain
  client_id     = var.auth0_client_id
  client_secret = var.auth0_client_secret
}

resource "auth0_tenant" "main" {
  friendly_name = "Teleport Challenge Tenant"
}

# Strong Authentication - Database Connection with Password Policy
resource "auth0_connection" "database" {
  name     = "Teleport-Challenge"
  strategy = "auth0"
  
  options {
    password_policy                = "fair"
    password_history {
      enable = true
      size   = 5
    }
    password_no_personal_info {
      enable = true
    }
    brute_force_protection = true
    disable_signup         = false
    requires_username      = true
  }
}
