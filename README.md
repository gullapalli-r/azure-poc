# Azure POC - Multi-Environment Infrastructure Deployment

A production-ready Azure infrastructure deployment solution using **Bicep** Infrastructure as Code, demonstrating best practices for multi-environment deployments with GitHub Actions CI/CD automation.

## 📋 Overview

This repository showcases a complete infrastructure deployment pipeline with:
- **Multi-environment support** (Development & Production)
- **Reusable Bicep modules** for core Azure services
- **Composite stamps** for deploying related services together
- **Deployment stacks** for lifecycle management
- **OIDC-based authentication** for secure deployments
- **Environment-driven configuration** from a centralized config map

## 🏗️ Architecture

### Deployed Services (platform-services stamp)

| Service | Purpose | Configuration |
|---------|---------|---|
| **Log Analytics Workspace (LAW)** | Centralized logging & monitoring | All resources log diagnostics |
| **Storage Accounts** | Persistent data storage | 2 accounts: `logs` (Cool tier) & `data` (Hot tier with HNS) |
| **Container Registry (ACR)** | Private container image registry | Premium SKU with soft delete & quarantine policies |
| **Private Endpoints** | Private connectivity | All services isolated via private links |

### Multi-Environment Structure

```
environments/
├── dev/
│   └── eastus/
│       ├── main.platform.bicep          (dev02 environment)
│       ├── vnet/                        (Virtual Network)
│       └── stg/                         (Storage configuration)
└── prod/
    └── eastus/
        └── main.platform.bicep          (prod01 environment)
```

### Resource Naming Convention

Resources are auto-named using the pattern:
- **Storage:** `st{environment}{name}{shortName}` (e.g., `stdev02platformlogs`)
- **ACR:** `contreg{environment}{name}{shortName}` (e.g., `contregdev02platformacr01`)
- **LAW:** `LOG-{ENVIRONMENT}-{NAME}` (e.g., `LOG-DEV02-PLATFORM`)

## 🚀 Deployment Pipeline

### Workflow: `deploy-environments.yml`

Supports selective deployment with what-if validation:

```yaml
Inputs:
├── configuration: Target environment (rg-poc-dev-eastus | rg-poc-prod-eastus)
├── operation: What to deploy (deploy-all | deploy-virtual-network | deploy-storage-account | deploy-platform-services)
└── what-if: Preview changes before deployment (true | false)
```

### Deployment Flow

```
1. Config Mapping → Resolve environment-specific settings
2. Validation → Run what-if to preview changes
3. Deployment → Create/update deployment stack
4. Stack Management → Enable auto cleanup & deny settings
```

## 📦 Environment Configuration

Configuration is centralized in `.github/workflows/configuration-environment-map.jsonc`:

```jsonc
{
  "rg-poc-dev-eastus": {
    "RESOURCE_GROUP": "rg-poc-dev-eastus",
    "REGION": "eastus",
    "DEPLOYMENT_STACK_NAME": "poc-dev-stack",
    "ACTION_ON_UNMANAGE": "detachAll",
    "LANDING_ZONE_PATH": "dev/eastus"
  },
  "rg-poc-prod-eastus": {
    "RESOURCE_GROUP": "rg-poc-prod-eastus",
    "REGION": "eastus",
    "DEPLOYMENT_STACK_NAME": "poc-prod-stack",
    "ACTION_ON_UNMANAGE": "detachAll",
    "LANDING_ZONE_PATH": "prod/eastus"
  }
}
```

## 🔐 Authentication

- **Method:** OIDC Federation (passwordless)
- **Setup:** Federated credentials configured in Azure Entra ID
- **Environment:** GitHub repository environment mapped to Azure environment

### Required Secrets

```
AZURE_CLIENT_ID         # Service Principal Client ID
AZURE_TENANT_ID         # Azure Tenant ID
AZURE_SUBSCRIPTION_ID   # Target Subscription ID
```

## 📝 Deployment Examples

### 1. What-If Preview (Dev Environment)

```bash
# Via GitHub Actions UI
- Configuration: rg-poc-dev-eastus
- Operation: deploy-platform-services
- What-If: true
```

### 2. Deploy Platform Services

```bash
# Via GitHub Actions UI
- Configuration: rg-poc-dev-eastus
- Operation: deploy-platform-services
- What-If: false
```

### 3. Deploy All Resources

```bash
# Deploy VNet, Storage, and Platform Services together
- Configuration: rg-poc-prod-eastus
- Operation: deploy-all
- What-If: false
```

## 📊 Deployment Stacks

Resources are deployed as **Deployment Stacks** for enhanced lifecycle management:

- **Auto-cleanup:** Managed resources are automatically cleaned up when stack is deleted
- **Deny settings:** Prevents accidental deletion of critical resources
- **Tracking:** Single source of truth for all deployed resources

View stacks:
```bash
az stack group list --resource-group rg-poc-dev-eastus
az stack group show --name poc-dev-stack --resource-group rg-poc-dev-eastus
```

## 🔧 Resource Configuration

### Storage Accounts

**Dev Environment (Logs Storage):**
- Access tier: Cool
- Versioning: Enabled
- Retention: 30 days
- SFTP: Disabled

**Dev Environment (Data Storage):**
- Access tier: Hot
- Hierarchical namespace: Enabled (Data Lake)
- SFTP: Enabled
- Retention: 30 days

### Container Registry

- SKU: Premium
- Admin user: Disabled
- Quarantine policy: Enabled
- Soft delete: 30 days
- Export policy: Disabled
- Trusted services bypass: Enabled

### Private Endpoints

All services are isolated via Private Link:
- Integrated with private subnet: `SNET-SPOKE-PoC-EastUS-{env}-PrivateLink`
- DNS integration: Private
- Network security: NSG rules applied

## 📈 Monitoring & Diagnostics

All resources send diagnostics to Log Analytics Workspace:
- Storage accounts: Metrics & transaction logs
- ACR: Registry logs & audit events
- Network: NSG flow logs

Query example:
```kusto
AzureDiagnostics
| where ResourceType == "STORAGEACCOUNTS"
| where TimeGenerated > ago(24h)
| summarize Count by OperationName
```

## 🛠️ Manual Deployment (Azure CLI)

### What-If Preview

```bash
az deployment group what-if \
  --resource-group rg-poc-dev-eastus \
  --template-file ./environments/dev/eastus/main.platform.bicep
```

### Deploy with Stack

```bash
az stack group create \
  --name poc-dev-platform \
  --resource-group rg-poc-dev-eastus \
  --template-file ./environments/dev/eastus/main.platform.bicep \
  --action-on-unmanage detachAll \
  --deny-settings-mode none
```

## 📚 Related Repositories

- **[azure-iac](https://github.com/gullapalli-r/azure-iac)** - Bicep module registry with constructs and stamps
  - Constructs: Virtual Network, Storage Account, Container Registry, Log Analytics, Private Endpoint, Virtual Machine
  - Stamps: Platform Services (composite deployment)

## 🔄 CI/CD Workflow

```
Push to main
    ↓
Trigger deploy-environments.yml
    ↓
Select configuration & operation
    ↓
Run config mapping
    ↓
Execute what-if validation
    ↓
Deploy with deployment stack
    ↓
Resources available in Azure
```

## ✅ Deployment Checklist

Before deploying, ensure:

- [ ] Azure subscription and resource groups created
- [ ] Service Principal configured with OIDC federation
- [ ] GitHub repository secrets configured
- [ ] Target VNet and private link subnet exist
- [ ] Bicep registry accessible (br:bicepiacregistry.azurecr.io)

## 🚫 Troubleshooting

### Deployment Stack Not Created

**Issue:** Only regular deployments visible, no stacks

**Solution:** Ensure `az stack` CLI support (Azure CLI v2.61+)
```bash
az version  # Check CLI version
az extension add --name stack  # Add if needed
```

### Path Not Found Error

**Issue:** `environments/environments/dev/eastus/...`

**Solution:** Config map should contain only `dev/eastus` (not full path)

### ACR Access Denied

**Issue:** OIDC authentication timeout

**Solution:** Verify federated credentials subject matches GitHub context:
```
repo:gullapalli-r/azure-poc:environment:rg-poc-dev-eastus
```

## 📖 Documentation

- **Architecture decisions:** See stamp README in azure-iac
- **Module details:** Reference azure-iac construct modules
- **Bicep deployment:** [Microsoft Bicep Docs](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

## 🤝 Contributing

1. Create feature branch from `main`
2. Update Bicep templates as needed
3. Run `bicep build` to generate ARM templates
4. Test with what-if in a dev environment
5. Submit PR with deployment validation

## 📄 License

See [LICENSE](LICENSE) file

---

**Last Updated:** 2026-07-14  
**Status:** Production Ready ✅
