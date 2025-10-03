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
│   ├── auth0-tenant-setup.yml
│   ├── terraform-apply.yml
terraform/
├── auth0-tenant/          # Auth0 tenant and database setup
│   ├── main.tf           # Tenant and connection configuration
│   └── variables.tf      # Input variables
├── auth0-grafana/        # Grafana OIDC application
│   ├── main.tf           # OIDC application configuration
│   ├── roles.tf          # Role definitions
│   └── variables.tf      # Input variables
└── user-updater/
│   ├── main.go           # Go app to update users and add to groups
```

## APIs and Integrations

### Auth0 Management API

#### Authentication Methods
**Client Credentials Flow** (Primary)
- Uses `AUTH0_CLIENT_ID` and `AUTH0_CLIENT_SECRET`
- Machine-to-machine authentication
- Required scopes: `read:users`, `create:users`, `update:users`, `read:roles`, `create:role_members`ails

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
    Blocked:       &user.Blocked,
    EmailVerified: &user.Verified,
    Connection:    stringPtr("Teleport-Challenge"),
}

// Role assignment
roleAssignment := &management.Role{ID: &roleID}
err = m.User.AssignRoles(ctx, userID, []*management.Role{roleAssignment})
```

### GitHub Actions API
- **Workflow Triggers**: Push events, manual dispatch
- **Secret Management**: Secure credential storage
- **Execution**: Multi-stage deployment pipeline

### AWS S3 API
- **Terraform State Hosting**: Persists state

### 

## Security Considerations

### Authentication Security

#### Password Policy
- **Strength**: Fair level (8+ characters, mixed case, numbers, symbols)
- **History**: 5 previous passwords remembered
- **Personal Info**: Validation against user profile data
- **Brute Force**: Automatic account lockout after failed attempts

### Authorization Security

#### Role-Based Access Control (RBAC)
1. **Grafana Admin**
    - Full system access

2. **Grafana Editor**
    - Dashboard creation and editing
    - Data source configuration

3. **Grafana Viewer**
    - Read-only access to dashboards
    - No configuration changes

### Infrastructure Security

#### Secret Management
- **GitHub Secrets**: Encrypted credential storage
- **Environment Variables**: Runtime configuration
- **No Hardcoded Credentials**: All secrets in github actions

### Data Protection

#### Encryption
- **In Transit**: TLS 1.2+ for all communications
- **At Rest**: AWS EBS encryption for persistent state storage
- **Database**: Auth0 tenant encryption
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
