# Auth0 with Grafana OIDC Config Design Proposal

### Architecture Overview

**Simple Flow:**
```
GitHub Actions → Auth0 Setup → Grafana OIDC → User Registration
```

**What happens:**
1. **GitHub Actions** runs the deployment workflow
2. **Auth0** gets configured with tenant, strong auth
3. **Grafana OIDC** sets up grafana oidc application
4. **User Registration** runs go script to add users to groups in Auth0

### Project Structure

```
.github/workflows
│   ├── auth0-tenant-setup.yml # Runs terraform-apply for the auth0-tenant workspace
│   ├── auth0-grafana.yml      # Runs terraform-apply for the auth0-grafana workspace
│   ├── auth0-users.yml        # Runs go script for the auth0 user creation
│   ├── terraform-apply.yml    # Generic terraform-apply which can be reused
terraform/
├── auth0-tenant/         # Auth0 tenant and database setup 
│   ├── main.tf           # Tenant and connection configuration
│   └── variables.tf      # Input variables
├── auth0-grafana/        # Grafana OIDC application
│   ├── main.tf           # OIDC application configuration
│   ├── roles.tf          # Role definitions
│   └── variables.tf      # Input variables
user-updater/
│   ├── main.go           # Go app to update users and add to groups
│   ├── users.yaml        # list of users for go app to consume
```

### Auth0 Tenant Module (`terraform/auth0-tenant/`)

#### Resources Created:
1. **`auth0_tenant`** - Main tenant configuration

2. **`auth0_connection`** - Database connection with strong authentication

#### Required API Scopes:
- `read:tenant_settings`
- `update:tenant_settings`
- `create:connections`
- `read:connections`
- `update:connections`

### Auth0 Grafana Module (`terraform/auth0-grafana/`)

#### Resources Created:
1. **`auth0_client`** - OIDC application for Grafana

#### Required API Scopes:
- `create:clients`
- `read:clients`
- `update:clients`

### User Management Go Application

#### Auth0 Management API Integration:
- user management go application is used to update users and add them to roles

#### Required API Scopes for Go Application:
- `read:users`
- `create:users`
- `update:users`
- `read:roles`

## APIs and Integrations

### Auth0 Management API

#### Authentication Methods
**Client Credentials Flow** (Primary)
- Uses `AUTH0_CLIENT_ID` and `AUTH0_CLIENT_SECRET`
- Machine-to-machine authentication
- Required scopes: `read:users`, `create:users`, `update:users`, `read:roles`

#### Go SDK Integration
Github actions will passthrough credentials from secrets to environment variables for the go app
```go
// Client initialization
m, err := management.New(domain, management.WithClientCredentials(ctx, clientID, clientSecret))

// User creation
userData := &management.User{
   Email:         &user.Email,
   Password:      &user.Password,
   Name:          &user.Name,
   PhoneNumber:   &user.Phone,
   Blocked:       &user.Blocked,
   EmailVerified: &user.Verified,
   Connection:    stringPtr("Teleport-Challenge"), // Use the database connection from Terraform
}

// Role assignment
roleAssignment := &management.Role{ID: &roleID}
err = m.User.AssignRoles(ctx, userID, []*management.Role{roleAssignment})
```

### Adding users

#### User Creation Process
The Go application handles user creation with Auth0's Management API.
Users are added to users.yaml file

#### User Data Structure
```yaml
users:
  - email: "admin@teleport-challenge.com"
    password: "SecurePass123!"
    name: "Admin User"
    phone: "+19165550101"
    role: "Grafana Admin"
    blocked: false
    verified: true
```

### GitHub Actions API
- **Workflow Triggers**: Manual dispatch
- **Secret Management**: Secure credential storage
- **Execution**: Multi-stage deployment pipeline

#### Workflow Files:
- **`auth0-tenant-setup.yml`**: Workflow that configures Auth0 tenant, password policies, MFA
- **`auth0-grafana.yml`**: Workflow to configure only the Grafana OIDC application
- **`auth0-users.yml`**: Workflow to register users and assign them to Grafana roles
- **`terraform-apply.yml`**: Reusable workflow for running Terraform apply

## Security Considerations

### Authentication Security

#### Password Policy
- **Strength**: Fair level (8+ characters, mixed case, numbers, symbols)
- **History**: 5 previous passwords remembered
- **Personal Info**: Validation against user profile data
- **MFA Enabled**: MFA will be enabled to help protect against phishing

### MFA Setup
This setup will use the auth0 provider for SMS and voice MFA. It will use the PhoneNumber value from the `management.User` struct of the Auth0 SDK
```hcl
resource "auth0_guardian" "mfa" {
  policy = "all-applications"
  
  phone {
    enabled = true
    provider = "auth0"
    message_types = ["sms", "voice"]
  }
}
```

### Infrastructure Security

#### Secret Management
- **GitHub Secrets**: Encrypted credential storage
- **Environment Variables**: Runtime configuration
- **No Hardcoded Credentials**: All secrets in github actions

### Data Protection

#### Encryption
- **In Transit**: TLS 1.2+ for all communications
- **Database**: Auth0 bcrypt server side encryption
- **Secrets**: GitHub encrypted storage

## Edge Cases and Error Handling

### User Management Edge Cases

#### Duplicate User Handling
Similar to terraform we do not add resources (users in this case) if they already exist
```go
// Check for existing users before creation
existingUsers, err := m.User.Search(ctx, management.Query(fmt.Sprintf("email:%s", user.Email)))
if len(existingUsers.Users) > 0 {
fmt.Printf("User %s already exists, skipping creation\n", user.Email)
continue
}
```
#### Duplicate Auth0 Resouces Handling
The inclusion of the remote state for terraform easily handles the edge case where resources already exist.

### Changes and Review process
Currently, collaborators/owners can make a PR to this repo and submit it for review. Once the PR has +2 approvals it can be merged.
The current setup requires a PR to be merged onto main before it can be deployed with a workflow dispatch.