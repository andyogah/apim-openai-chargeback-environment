# Deployment Guide

## Pre-Deployment Checklist

### Azure Prerequisites
- [ ] Azure subscription with sufficient permissions
- [ ] Resource group created
- [ ] Azure CLI installed and configured
- [ ] **Primary**: Azure Bicep CLI extension installed
- [ ] **Alternative**: Terraform v1.5+, ARM templates, or Pulumi
- [ ] Service principal created for automation

### Local Environment Setup
- [ ] Git repository cloned
- [ ] Environment variables configured
- [ ] Dependencies installed
- [ ] Access to Azure DevOps/GitHub Actions

## Infrastructure-as-Code Options

This solution supports multiple IaC tools to accommodate different organizational preferences:

### 1. Azure Bicep (Recommended)
**Why Bicep?**
- Native Azure integration
- Simplified syntax
- Better type safety
- Built-in validation
- Seamless ARM template compilation

### 2. Terraform (Alternative)
**When to use Terraform?**
- Multi-cloud requirements
- Existing Terraform infrastructure
- Team expertise with Terraform
- Complex state management needs

### 3. ARM Templates (Alternative)
**When to use ARM Templates?**
- Legacy infrastructure requirements
- Existing ARM template investments
- Azure Resource Manager direct integration

### 4. Pulumi (Alternative)
**When to use Pulumi?**
- Programming language preference
- Complex logic requirements
- Modern infrastructure development

## Step-by-Step Deployment

### Option 1: Azure Bicep Deployment (Recommended)

#### 1. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

#### 2. Bicep Template Validation
```bash
# Navigate to Bicep directory
cd infrastructure/bicep

# Install Bicep CLI (if not already installed)
az bicep install

# Validate template syntax
az bicep build --file main.bicep

# Validate deployment (what-if)
az deployment group what-if \
  --resource-group rg-apim-openai-dev \
  --template-file main.bicep \
  --parameters @parameters/dev.json
```

#### 3. Infrastructure Deployment
```bash
# Development environment
az deployment group create \
  --resource-group rg-apim-openai-dev \
  --template-file main.bicep \
  --parameters @parameters/dev.json \
  --confirm-with-what-if

# Production environment
az deployment group create \
  --resource-group rg-apim-openai-prod \
  --template-file main.bicep \
  --parameters @parameters/prod.json \
  --confirm-with-what-if
```

### Option 2: Terraform Deployment (Alternative)

#### 1. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

#### 2. Terraform Initialization
```bash
# Navigate to Terraform directory
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Create workspace (if using Terraform Cloud)
terraform workspace new dev
```

#### 3. Infrastructure Deployment
```bash
# Plan deployment
terraform plan -var-file="environments/dev.tfvars"

# Apply configuration
terraform apply -var-file="environments/dev.tfvars"
```

### Option 3: ARM Templates Deployment (Alternative)

#### 1. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

#### 2. ARM Template Deployment
```bash
# Navigate to ARM templates directory
cd infrastructure/arm

# Validate template
az deployment group validate \
  --resource-group rg-apim-openai-dev \
  --template-file azuredeploy.json \
  --parameters @parameters/dev.parameters.json

# Deploy template
az deployment group create \
  --resource-group rg-apim-openai-dev \
  --template-file azuredeploy.json \
  --parameters @parameters/dev.parameters.json
```

### Option 4: Pulumi Deployment (Alternative)

#### 1. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

#### 2. Pulumi Deployment
```bash
# Navigate to Pulumi directory
cd infrastructure/pulumi

# Install dependencies
npm install

# Login to Pulumi
pulumi login

# Select or create stack
pulumi stack select dev

# Deploy infrastructure
pulumi up
```

## Common Deployment Steps (All IaC Tools)

### 3. Function App Deployment
```bash
# Set up Python environment
cd function-app
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Test locally (optional)
func start

# Deploy to Azure (using Azure Functions Core Tools)
func azure functionapp publish <function-app-name>

# Or using Azure CLI with zip deployment
zip -r function-app.zip . -x "venv/*" "tests/*" "*.pyc" "__pycache__/*"
az functionapp deployment source config-zip \
  --resource-group <resource-group> \
  --name <function-app-name> \
  --src function-app.zip
```

### 4. APIM Policy Configuration
```bash
# Deploy APIM policies
cd ../policies
./deploy-policies.sh

# Or manually deploy policies
az apim api policy create \
  --resource-group <resource-group> \
  --service-name <apim-service> \
  --api-id <api-id> \
  --policy-file inbound-policy.xml
```

### 5. Post-Deployment Configuration
```bash
# Configure monitoring
./scripts/setup-monitoring.sh

# Run health checks
./scripts/health-check.sh

# Validate deployment
./scripts/validate-deployment.sh

# Test Python functions
cd function-app
python -m pytest tests/integration/
```

## Environment-Specific Deployments

### Development Environment
```bash
# Bicep deployment
az deployment group create \
  --resource-group rg-apim-openai-dev \
  --template-file main.bicep \
  --parameters @parameters/dev.json

# Terraform deployment
terraform apply -var-file="environments/dev.tfvars"
```

**Development Environment Features:**
- Single region deployment
- Basic monitoring
- Development SKUs
- Reduced redundancy

### Production Environment
```bash
# Bicep deployment with what-if preview
az deployment group create \
  --resource-group rg-apim-openai-prod \
  --template-file main.bicep \
  --parameters @parameters/prod.json \
  --confirm-with-what-if

# Terraform deployment with plan review
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
terraform apply prod.tfplan
```

**Production Environment Features:**
- Multi-region deployment
- Full monitoring and alerting
- Production SKUs
- High availability
- Backup and disaster recovery

## CI/CD Pipeline Integration

### Azure DevOps Pipeline (Bicep)
```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop

stages:
- stage: Deploy
  jobs:
  - job: DeployInfrastructure
    steps:
    - task: AzureCLI@2
      displayName: 'Deploy Bicep Template'
      inputs:
        azureSubscription: 'Azure Service Connection'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az deployment group create \
            --resource-group $(resourceGroupName) \
            --template-file infrastructure/bicep/main.bicep \
            --parameters @infrastructure/bicep/parameters/$(environment).json
```

### GitHub Actions (Terraform)
```yaml
# .github/workflows/deploy.yml
name: Deploy Infrastructure
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Deploy Infrastructure
        run: |
          cd infrastructure/terraform
          terraform init
          terraform apply -var-file="environments/prod.tfvars" -auto-approve
```

## Troubleshooting Deployment Issues

### Common Issues by IaC Tool

#### Bicep Issues
1. **Template Validation Errors**
   - Check syntax with `az bicep build`
   - Verify parameter files are valid JSON
   - Ensure resource names are unique

2. **Resource Deployment Failures**
   - Check Azure service limits
   - Verify resource group permissions
   - Review activity logs in Azure portal

#### Terraform Issues
1. **State File Issues**
   - Check Terraform state file integrity
   - Verify backend configuration
   - Use `terraform refresh` to sync state

2. **Provider Version Conflicts**
   - Check provider version constraints
   - Use `terraform init -upgrade`
   - Review provider documentation

#### ARM Template Issues
1. **Parameter Validation**
   - Validate parameter files syntax
   - Check parameter dependencies
   - Verify parameter types

2. **Resource Conflicts**
   - Check for existing resources
   - Verify resource naming conventions
   - Review deployment mode settings

### General Troubleshooting Steps
1. **Permission Errors**: Check service principal permissions
2. **Network Issues**: Check NSG rules and firewalls
3. **Configuration Errors**: Validate environment variables
4. **Resource Limits**: Check Azure subscription limits

### Validation Commands

#### Bicep Validation
```bash
# Validate template
az bicep build --file main.bicep

# What-if deployment
az deployment group what-if \
  --resource-group <resource-group> \
  --template-file main.bicep \
  --parameters @parameters/dev.json
```

#### Terraform Validation
```bash
# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="environments/dev.tfvars"
```

#### ARM Template Validation
```bash
# Validate template
az deployment group validate \
  --resource-group <resource-group> \
  --template-file azuredeploy.json \
  --parameters @parameters/dev.parameters.json
```

### Post-Deployment Validation
1. Check resource group deployment status
2. Verify APIM policies are applied
3. Test API endpoints
4. Validate monitoring setup
5. Check Function App logs
6. Verify Redis cache connectivity
7. Test OpenAI service integration
8. Run Python function tests
9. Check Python dependencies installation
10. Validate function app runtime configuration

### Function App Specific Validation
```bash
# Check function app status
az functionapp show --name <function-app-name> --resource-group <resource-group>

# View function app logs
az functionapp log tail --name <function-app-name> --resource-group <resource-group>

# Test individual functions
curl -X POST "https://<function-app-name>.azurewebsites.net/api/usage-tracking" \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Check Python runtime
az functionapp config show --name <function-app-name> --resource-group <resource-group>
```

## Migration Between IaC Tools

### Bicep to Terraform Migration
```bash
# Export existing resources
az resource list --resource-group <resource-group> --output table

# Use Terraform import for existing resources
terraform import azurerm_resource_group.example /subscriptions/.../resourceGroups/example
```

### ARM to Bicep Migration
```bash
# Decompile ARM template to Bicep
az bicep decompile --file azuredeploy.json
```

### Terraform to Bicep Migration
```bash
# Export Terraform state
terraform show -json > terraform.json

# Manual migration required - use exported state as reference
```

## Best Practices

### IaC Tool Selection
- **Choose Bicep** for Azure-native development
- **Choose Terraform** for multi-cloud or existing Terraform infrastructure
- **Choose ARM Templates** for legacy compatibility
- **Choose Pulumi** for complex programming logic

### Deployment Best Practices
1. Always use parameter files for different environments
2. Implement proper CI/CD pipelines
3. Use what-if/plan commands before deployment
4. Implement proper state management
5. Use resource tagging for organization
6. Implement proper access controls
7. Regular backup of state files (Terraform)

### Environment Management
- Use separate resource groups per environment
- Implement proper naming conventions
- Use Azure Policy for governance
- Implement cost management controls
- Regular security assessments
