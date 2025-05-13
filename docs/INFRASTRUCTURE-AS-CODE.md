# Infrastructure as Code with Bicep

This document describes the Infrastructure as Code (IaC) approach used in this project, which leverages Azure Bicep templates to define and deploy Azure resources.

## Overview

The IaC approach allows you to:
- Define infrastructure in a declarative way
- Version control your infrastructure definitions
- Deploy consistent environments
- Validate infrastructure against compliance requirements
- Automate the deployment and testing process

## Structure

The Bicep templates are organized as follows:

```
infra/
├── main.bicep                  # Main deployment template
└── modules/                    # Reusable resource modules
    ├── keyVault.bicep          # Key Vault module
    ├── networkSecurityGroup.bicep  # NSG module
    ├── privateDnsZone.bicep    # Private DNS Zone module
    ├── storageAccount.bicep    # Storage Account module
    ├── subnet.bicep            # Subnet module
    └── virtualNetwork.bicep    # Virtual Network module
```

## Modules

Each module is designed to be reusable and configurable:

### Storage Account Module
- Configurable SKU, kind, and security settings
- TLS version controls
- Public access controls

### Key Vault Module
- SKU configuration
- Soft delete and purge protection settings
- Access policy configuration

### Virtual Network Module
- Address space configuration
- Location settings
- Tagging support

### Subnet Module
- Address prefix configuration
- Service endpoint support
- Private endpoint policy settings

### Network Security Group Module
- Security rule configuration
- Rule priority management
- Protocol and port settings

### Private DNS Zone Module
- Zone name configuration
- Global deployment setup

## Deployment Process

The deployment process is automated through the `Deploy-Test-Visualize.ps1` script, which:

1. Checks if the target resource group exists and creates it if needed
2. Deploys the Bicep templates to the resource group
3. Captures deployment outputs for use by tests
4. Runs tests against the deployed infrastructure
5. Visualizes test results through the Node.js server

## Customizing Deployments

To customize the infrastructure deployment:

1. Edit the `main.bicep` file to add or modify resource definitions
2. Update module parameters as needed for specific requirements
3. Create new module files for additional resource types
4. Adjust the deployment script parameters to target different environments

## Example: Adding a New Resource

To add a new Azure SQL Server to the deployment:

1. Create a new module file `infra/modules/sqlServer.bicep`
2. Define the parameters and resource in the module
3. Add a module reference in `main.bicep`:

```bicep
module sqlServer 'modules/sqlServer.bicep' = {
  name: 'sqlServer-deployment'
  params: {
    name: 'sql${resourceToken}'
    location: location
    // other parameters
  }
}
```

4. Run the deployment script to deploy the updated infrastructure

## Integration with Testing

The infrastructure deployment is integrated with the testing framework through:

1. Deployment outputs saved to the TestResults directory
2. Test files that read these outputs to identify resource names
3. Comparison of deployed resources against expected configurations
4. Visualization of test results showing compliance and issues

## Best Practices

- Use parameters for all configurable values
- Include sensible defaults for optional parameters
- Use consistent naming conventions
- Include appropriate tags on resources
- Structure modules for reusability
- Keep module interfaces simple but flexible
- Document parameters and outputs
- Version control all templates
