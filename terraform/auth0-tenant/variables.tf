variable "auth0_domain" {
  description = "Auth0 domain"
  type        = string
  default       = "dev-i7byu1nxmf5j3pj4.us.auth0.com"
}

variable "auth0_client_id" {
  description = "Auth0 client ID"
  type        = string
  default       = "kVfvBeMccQ0Y3MMpARq6ZRR6PCmV6z2J"
}

variable "auth0_client_secret" {
  description = "Auth0 client secret"
  type        = string
  sensitive   = true
  default       = "VqPLQPw6pEVJVvc9M3zCpiRiJFN7me4iS9wuiTZX44m4uDp6pjVO7O8C_qRNbDg5"
}

