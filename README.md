# Azure API Management OpenAI Chargeback Environment

A comprehensive solution for implementing scalable OpenAI usage tracking and chargeback mechanisms through Azure API Management, addressing payload size limitations and data persistence concerns.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Azure](https://img.shields.io/badge/Azure-0078D4?logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com)
[![OpenAI](https://img.shields.io/badge/OpenAI-412991?logo=openai&logoColor=white)](https://openai.com)
[![Bicep](https://img.shields.io/badge/Bicep-0078D4?logo=microsoft-azure&logoColor=white)](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)

## Table of Contents
- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Solution Architecture](#solution-architecture)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Usage](#usage)
- [Configuration](#configuration)
- [Security](#security)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Performance Optimization](#performance-optimization)
- [Cost Management](#cost-management)
- [Best Practices](#best-practices)
- [API Documentation](#api-documentation)
- [Contributing](#contributing)
- [Testing](#testing)
- [FAQ](#faq)
- [Changelog](#changelog)

## Overview

### What
This repository provides a complete Infrastructure-as-Code (IaC) solution for implementing OpenAI usage chargeback in enterprise environments using Azure API Management. The solution addresses scalability challenges and data persistence concerns while providing comprehensive usage tracking and billing capabilities.

**Key Features:**
- 🚀 Scalable architecture handling large payloads (>8192 bytes)
- 💰 Real-time cost tracking and chargeback reporting
- 🔒 Security-first design with minimal data persistence
- 📊 Comprehensive monitoring and alerting
- 🏗️ Infrastructure-as-Code with Azure Bicep (primary) and Terraform (optional)
- 🔄 CI/CD ready with automated deployments
- 📈 Performance optimization for high-throughput scenarios

### Why
- **Payload Size Limitations**: Azure APIM Diagnostic Logs have an 8192-byte limit for Log Analytics Workspaces, causing truncation of larger payloads
- **Data Privacy Concerns**: Organizations need flexible data retention policies and minimal data persistence for security compliance
- **Cost Management**: Enterprises require detailed usage tracking and chargeback mechanisms for OpenAI services
- **Scalability**: Need for handling both streaming and batch data processing scenarios
- **Compliance**: Meet enterprise security and governance requirements

### Who (Audience)
- **Primary**: Enterprise Azure architects and DevOps engineers
- **Secondary**: Security teams, Cost management teams, AI/ML platform teams
- **Tertiary**: Compliance officers and data governance teams
- **End Users**: Developers consuming OpenAI services through the platform

### When
- **Initial Release**: March 15, 2025
- **Target Deployment**: Production-ready for enterprise environments
- **Maintenance**: Ongoing updates based on Azure service evolution
- **Support Lifecycle**: Long-term support with regular updates

### Where
- **Cloud Platform**: Microsoft Azure
- **Deployment Regions**: Multi-region capable (Primary: East US, West Europe)
- **Network Integration**: Enterprise network-ready with NSG compatibility
- **Environments**: Development, Staging, Production

## Problem Statement

### Current Challenges
1. **Log Size Limitations**: APIM Diagnostic Logs truncate at 8192 bytes, insufficient for large OpenAI payloads
2. **Data Persistence**: Security requirements demand minimal data retention with flexible policies
3. **Scalability**: Need to handle varying data volumes and formats
4. **Cost Tracking**: Lack of granular usage tracking and chargeback mechanisms
5. **Performance**: Latency concerns with traditional logging approaches
6. **Compliance**: Meeting enterprise security and audit requirements

### Business Impact
- **Cost Overruns**: Uncontrolled OpenAI usage without proper tracking
- **Security Risks**: Sensitive data persistence in logs
- **Performance Issues**: Slow response times due to logging overhead
- **Compliance Gaps**: Inability to meet audit and governance requirements

### Technical Requirements
- Handle streaming and batch data processing
- Support various natural language data formats
- Provide data veracity and validation
- Deliver actionable chargeback insights
- Maintain low operational costs
- Ensure high maintainability and reproducibility
- Enable automated workflows
- Support multi-tenant architectures

## Solution Architecture

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI Chatbot    │───▶│   API Gateway   │───▶│   Azure OpenAI  │
│   (LibreChat)   │    │   (APIM)        │    │   Service       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  Function App   │
                       │  (Processing)   │
                       └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  Redis Cache    │
                       │  (Temp Storage) │
                       └─────────────────┘
```

### Detailed Component Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                           Client Layer                          │
├─────────────────────────────────────────────────────────────────┤
│  LibreChat │  Custom Apps │  Postman │  SDK Clients │  Web Apps │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        API Gateway Layer                        │
├─────────────────────────────────────────────────────────────────┤
│         Azure API Management (APIM)                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐│
│  │   Auth      │ │   Rate      │ │   Policy    │ │   Logging   ││
│  │  Policies   │ │  Limiting   │ │ Enforcement │ │  Policies   ││
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘│
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Processing Layer                          │
├─────────────────────────────────────────────────────────────────┤
│                    Azure Functions                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐│
│  │   Usage     │ │  Chargeback │ │   Cost      │ │  Reporting  ││
│  │  Tracking   │ │ Calculation │ │ Allocation  │ │  Generator  ││
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘│
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Storage Layer                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐│
│  │   Redis     │ │   Cosmos    │ │   Blob      │ │    Key      ││
│  │   Cache     │ │     DB      │ │  Storage    │ │   Vault     ││
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘│
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AI Services Layer                         │
├─────────────────────────────────────────────────────────────────┤
│                      Azure OpenAI                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐│
│  │   GPT-4     │ │   GPT-3.5   │ │   Codex     │ │   DALL-E    ││
│  │   Models    │ │   Models    │ │   Models    │ │   Models    ││
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow
1. **Request Processing**: Client → APIM → Azure Functions → Azure OpenAI
2. **Response Processing**: Azure OpenAI → Azure Functions → APIM → Client
3. **Usage Tracking**: Parallel processing to Redis Cache
4. **Chargeback Processing**: Batch processing from Redis to reporting systems

### Azure Resources
- **Azure OpenAI**: Core AI service endpoint
- **Azure API Management**: Gateway and policy enforcement
- **Azure Functions**: Serverless processing and chargeback logic
- **Azure Cache for Redis**: Temporary data storage and session management
- **Azure Cosmos DB**: Long-term usage data storage (optional)
- **Azure Blob Storage**: Report and backup storage
- **Azure Key Vault**: Secure credential management
- **Log Analytics Workspace**: Monitoring and diagnostics
- **Azure Monitor**: Alerting and dashboards
- **Azure Application Insights**: Performance monitoring

## Getting Started

### Prerequisites
- Azure subscription with appropriate permissions
- Azure CLI v2.50+ or PowerShell
- Docker Desktop (for local LibreChat instance)
- **Primary IaC Tool**: Azure Bicep (recommended)
- **Alternative IaC Tools**: Terraform v1.5+, ARM templates, Pulumi
- **Python 3.9+** (for Function App development)
- **Azure Functions Core Tools v4.x**
- Git for version control

### System Requirements
- **Development Machine**: Windows 10+, macOS 12+, or Linux
- **Memory**: 8GB RAM minimum, 16GB recommended
- **Storage**: 10GB available disk space
- **Network**: Stable internet connection

### Quick Start

#### Option 1: Azure Bicep (Recommended)
```bash
# 1. Clone the repository
git clone https://github.com/your-org/apim-openai-chargeback-environment.git
cd apim-openai-chargeback-environment

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your Azure credentials

# 3. Set up Python environment and build Function App
cd function-app
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# 4. Deploy infrastructure using Bicep
cd ../infrastructure/bicep
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters @parameters/dev.json

# 5. Deploy Function App
cd ../../function-app
func azure functionapp publish <function-app-name>

# 6. Configure APIM policies
cd ../scripts
./deploy-policies.sh

# 7. Set up monitoring
./setup-monitoring.sh
```

#### Option 2: Terraform (Alternative)
```bash
# 1. Clone the repository
git clone https://github.com/your-org/apim-openai-chargeback-environment.git
cd apim-openai-chargeback-environment

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your Azure credentials

# 3. Set up Python environment and build Function App
cd function-app
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# 4. Initialize Terraform
cd ../infrastructure/terraform
terraform init

# 5. Deploy infrastructure
terraform apply -var-file="environments/dev.tfvars"

# 6. Deploy Function App
cd ../../function-app
func azure functionapp publish <function-app-name>

# 7. Configure APIM policies
cd ../scripts
./deploy-policies.sh

# 8. Set up monitoring
./setup-monitoring.sh
```

#### Option 3: ARM Templates (Alternative)
```bash
# 1. Clone the repository
git clone https://github.com/your-org/apim-openai-chargeback-environment.git
cd apim-openai-chargeback-environment

# 2. Set up Python environment and build Function App
cd function-app
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# 3. Deploy using ARM templates
cd ../infrastructure/arm
az deployment group create \
  --resource-group myResourceGroup \
  --template-file azuredeploy.json \
  --parameters @parameters/dev.parameters.json

# 4. Deploy Function App
cd ../../function-app
func azure functionapp publish <function-app-name>
```

### Repository Structure
NOTE: The app works as is, but in the process of tidying the structure to  what is shown below. WIP
```
infrastructure/
├── bicep/                 # Primary IaC (Recommended)
│   ├── main.bicep
│   ├── modules/
│   └── parameters/
├── terraform/             # Alternative IaC
│   ├── main.tf
│   ├── variables.tf
│   └── environments/
├── arm/                   # Alternative IaC
│   ├── azuredeploy.json
│   └── parameters/
└── pulumi/               # Alternative IaC
    ├── index.ts
    └── Pulumi.yaml
function-app/             # Python Azure Functions
├── usage_tracking/
│   ├── __init__.py
│   └── function_app.py
├── chargeback_calculation/
│   ├── __init__.py
│   └── function_app.py
├── cost_allocation/
│   ├── __init__.py
│   └── function_app.py
├── report_generation/
│   ├── __init__.py
│   └── function_app.py
├── shared/
│   ├── __init__.py
│   ├── models.py
│   └── utils.py
├── tests/
├── host.json
├── local.settings.json
├── requirements.txt
└── function_app.py
```

### APIM Policy Configuration
The solution includes custom APIM policies for:
- **Request/response logging**: Capture and process API calls
- **Usage tracking**: Monitor token consumption and costs
- **Rate limiting**: Prevent abuse and control usage
- **Authentication/authorization**: Secure API access
- **Payload size management**: Handle large payloads efficiently
- **Error handling**: Graceful error management and reporting

### Function App Deployment
Automated deployment through Azure DevOps pipelines or GitHub Actions:

```yaml
# Example GitHub Actions workflow
name: Deploy Infrastructure and Function App
on:
  push:
    branches: [main]
jobs:
  deploy-infrastructure:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy Bicep Template
        uses: azure/arm-deploy@v1
        with:
          resourceGroupName: ${{ secrets.RESOURCE_GROUP }}
          template: ./infrastructure/bicep/main.bicep
          parameters: ./infrastructure/bicep/parameters/prod.json
  
  deploy-function-app:
    needs: deploy-infrastructure
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      - name: Install dependencies
        run: |
          cd function-app
          python -m pip install --upgrade pip
          pip install -r requirements.txt
      - name: Deploy to Azure Functions
        uses: Azure/functions-action@v1
        with:
          app-name: ${{ secrets.AZURE_FUNCTIONAPP_NAME }}
          package: ./function-app
          publish-profile: ${{ secrets.AZURE_FUNCTIONAPP_PUBLISH_PROFILE }}
```

## Usage

### Chargeback Data Example
The solution provides detailed usage tracking as shown below:

![Example of chargeback table](app/backend/example-log-chargeback.png)

### API Endpoints
- `POST /api/v1/openai/chat/completions` - OpenAI chat completions
- `POST /api/v1/openai/completions` - OpenAI completions
- `GET /api/v1/usage/summary` - Usage summary
- `GET /api/v1/chargeback/report` - Chargeback report
- `GET /api/v1/health` - Health check endpoint
- `GET /api/v1/metrics` - Usage metrics

### SDK Usage Examples

#### Python (Primary)
```python
import requests
import asyncio
import aiohttp

# Synchronous usage
response = requests.post(
    "https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions",
    headers={
        "Ocp-Apim-Subscription-Key": "your-subscription-key",
        "Content-Type": "application/json"
    },
    json={
        "model": "gpt-4",
        "messages": [{"role": "user", "content": "Hello!"}]
    }
)

# Asynchronous usage
async def call_openai_api():
    async with aiohttp.ClientSession() as session:
        async with session.post(
            "https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions",
            headers={
                "Ocp-Apim-Subscription-Key": "your-subscription-key",
                "Content-Type": "application/json"
            },
            json={
                "model": "gpt-4",
                "messages": [{"role": "user", "content": "Hello!"}]
            }
        ) as response:
            return await response.json()

# Usage
result = asyncio.run(call_openai_api())
```

#### C# (.NET)
```csharp
using System.Net.Http;
using System.Text;
using System.Text.Json;

var client = new HttpClient();
client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", "your-subscription-key");

var request = new
{
    model = "gpt-4",
    messages = new[] { new { role = "user", content = "Hello!" } }
};

var json = JsonSerializer.Serialize(request);
var content = new StringContent(json, Encoding.UTF8, "application/json");

var response = await client.PostAsync(
    "https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions",
    content);
```

#### PowerShell
```powershell
$headers = @{
    "Ocp-Apim-Subscription-Key" = "your-subscription-key"
    "Content-Type" = "application/json"
}

$body = @{
    model = "gpt-4"
    messages = @(@{
        role = "user"
        content = "Hello!"
    })
} | ConvertTo-Json -Depth 3

$response = Invoke-RestMethod -Uri "https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions" -Method POST -Headers $headers -Body $body
```

#### Node.js
```javascript
const axios = require('axios');

const response = await axios.post(
    'https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions',
    {
        model: 'gpt-4',
        messages: [{ role: 'user', content: 'Hello!' }]
    },
    {
        headers: {
            'Ocp-Apim-Subscription-Key': 'your-subscription-key',
            'Content-Type': 'application/json'
        }
    }
);
```

## Configuration

### Environment Variables
```bash
# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=https://your-openai-instance.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key
AZURE_OPENAI_API_VERSION=2023-12-01-preview

# Redis Configuration
REDIS_CONNECTION_STRING=your-redis-connection-string
REDIS_DATABASE=0
REDIS_TTL=3600

# APIM Configuration
APIM_SUBSCRIPTION_KEY=your-apim-subscription-key
APIM_GATEWAY_URL=https://your-apim-instance.azure-api.net

# Function App Configuration
FUNCTION_APP_NAME=your-function-app-name
FUNCTION_APP_KEY=your-function-app-key

# Monitoring Configuration
APPLICATION_INSIGHTS_CONNECTION_STRING=your-app-insights-connection-string
LOG_ANALYTICS_WORKSPACE_ID=your-workspace-id
```

### IaC Configuration Files
The solution provides configuration files for all supported IaC tools:

#### Bicep Parameters
Located in `/infrastructure/bicep/parameters/`:
- `dev.json` - Development environment parameters
- `test.json` - Test environment parameters
- `prod.json` - Production environment parameters

#### Terraform Variables
Located in `/infrastructure/terraform/environments/`:
- `dev.tfvars` - Development environment variables
- `test.tfvars` - Test environment variables
- `prod.tfvars` - Production environment variables

#### ARM Parameters
Located in `/infrastructure/arm/parameters/`:
- `dev.parameters.json` - Development environment parameters
- `test.parameters.json` - Test environment parameters
- `prod.parameters.json` - Production environment parameters

### APIM Policies
Configuration files located in `/policies/` directory:
- `inbound-policy.xml` - Request processing
- `outbound-policy.xml` - Response processing
- `on-error-policy.xml` - Error handling
- `cors-policy.xml` - Cross-origin resource sharing

## Security

### Security Considerations
- **Data Encryption**: All data encrypted in transit and at rest
- **Authentication**: Azure AD integration with RBAC
- **Network Security**: Private endpoints and NSG rules
- **Secrets Management**: Azure Key Vault for sensitive data
- **Audit Logging**: Comprehensive audit trail
- **Data Retention**: Configurable retention policies

### Security Best Practices
1. Use managed identities where possible
2. Implement least privilege access
3. Regular security assessments
4. Enable Azure Security Center recommendations
5. Monitor for suspicious activities

## Monitoring

### Key Metrics
- **Performance**: API request volume and latency
- **Usage**: OpenAI token usage and costs
- **Reliability**: Error rates and failure patterns
- **Efficiency**: Cache hit/miss ratios
- **Scalability**: Function execution metrics

### Alerting Rules
Configured alerts for:
- High API usage (>1000 requests/minute)
- Error rate thresholds (>5% error rate)
- Cost anomalies (>20% increase in daily costs)
- Performance degradation (>2s response time)
- Security incidents (failed authentication attempts)

### Dashboards
- **Executive Dashboard**: High-level cost and usage metrics
- **Operational Dashboard**: Real-time system health
- **Developer Dashboard**: API performance and usage
- **Security Dashboard**: Security events and compliance

## Troubleshooting

### Common Issues

#### High Latency
**Symptoms**: API responses taking >2 seconds
**Causes**: Network issues, Azure OpenAI throttling, Redis cache misses
**Solutions**:
1. Check Azure OpenAI service health
2. Verify Redis cache connectivity
3. Review APIM policy performance
4. Scale Function App instances

#### Authentication Failures
**Symptoms**: 401 Unauthorized errors
**Causes**: Expired keys, incorrect subscription keys, Azure AD issues
**Solutions**:
1. Verify APIM subscription key
2. Check Azure AD token validity
3. Review APIM authentication policies
4. Validate Key Vault access

#### Cost Anomalies
**Symptoms**: Unexpected cost increases
**Causes**: High usage, model changes, inefficient queries
**Solutions**:
1. Review usage patterns
2. Implement rate limiting
3. Optimize query efficiency
4. Set up cost alerts

### Debugging Tools
- Azure Application Insights for performance monitoring
- Log Analytics for log analysis
- Azure Monitor for alerting
- Postman for API testing

## Performance Optimization

### Optimization Strategies
1. **Caching**: Implement Redis caching for frequently accessed data
2. **Connection Pooling**: Use connection pooling for database connections
3. **Async Processing**: Implement asynchronous processing for non-critical tasks
4. **Load Balancing**: Use Azure Load Balancer for high availability
5. **CDN**: Implement Azure CDN for static content

### Performance Benchmarks
- **Target Response Time**: <1 second for 95% of requests
- **Throughput**: 1000+ requests per second
- **Availability**: 99.9% uptime
- **Cache Hit Rate**: >80% for frequently accessed data

## Cost Management

### Cost Optimization
- **Right-sizing**: Regularly review and adjust resource sizes
- **Reserved Instances**: Use reserved instances for predictable workloads
- **Spot Instances**: Use spot instances for non-critical workloads
- **Auto-scaling**: Implement auto-scaling to match demand
- **Cost Monitoring**: Set up cost alerts and budgets

### Cost Breakdown
- **Azure OpenAI**: 60-70% of total costs
- **Azure Functions**: 15-20% of total costs
- **Redis Cache**: 10-15% of total costs
- **Other Services**: 5-10% of total costs

## Best Practices

### Development Best Practices
1. Follow Infrastructure as Code principles
2. Implement comprehensive testing
3. Use version control for all configurations
4. Document all architectural decisions
5. Implement proper error handling

### Operational Best Practices
1. Monitor key metrics continuously
2. Implement automated backups
3. Regular security assessments
4. Capacity planning and scaling
5. Disaster recovery procedures

## API Documentation

### OpenAPI Specification
Full API documentation available at `/docs/openapi.yaml`

### Rate Limits
- **Free Tier**: 100 requests/minute
- **Basic Tier**: 1000 requests/minute
- **Premium Tier**: 10000 requests/minute

### Error Codes
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `429`: Too Many Requests
- `500`: Internal Server Error

## Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Standards
- Follow language-specific style guides
- Include comprehensive tests
- Document all public APIs
- Use meaningful commit messages

### Testing
- **Unit Tests**: Test individual components (pytest)
- **Integration Tests**: Test component interactions
- **End-to-End Tests**: Test complete workflows
- **Performance Tests**: Test under load

### Test Execution
```bash
# Run all tests
cd function-app
python -m pytest

# Run specific test categories
python -m pytest -m unit
python -m pytest -m integration
python -m pytest -m load

# Run with coverage
python -m pytest --cov=. --cov-report=html
```

## FAQ

### General Questions

**Q: What is the maximum payload size supported?**
A: The solution can handle payloads up to 100MB, significantly larger than the standard 8KB APIM limit.

**Q: How long is usage data retained?**
A: Usage data is retained for 30 days by default, configurable based on your requirements.

**Q: Can this solution be deployed in multiple regions?**
A: Yes, the solution supports multi-region deployment for high availability and disaster recovery.

**Q: Why is Bicep the recommended IaC tool?**
A: Bicep provides better Azure integration, simplified syntax, and native Azure service support. However, we support multiple IaC tools to accommodate different organizational preferences.

### Technical Questions

**Q: How does the solution handle Azure OpenAI throttling?**
A: The solution implements intelligent retry logic and request queuing to handle throttling gracefully using Python's `tenacity` library and asyncio for concurrent processing.

**Q: What happens if Redis cache is unavailable?**
A: The solution falls back to direct processing without caching, ensuring continued operation through Python's exception handling and circuit breaker patterns.

**Q: Can I use .NET instead of Python for the Function App?**
A: While the solution is designed for Python, Azure Functions support multiple runtimes. You can adapt the functions to .NET/C#, Node.js, or Java if preferred.

**Q: How do I migrate from ARM templates to Bicep?**
A: We provide migration scripts and documentation in the `/docs/migration/` directory to help with the transition.

**Q: What Python packages are used in the Function App?**
A: Key packages include `azure-functions`, `azure-cosmos`, `redis`, `aiohttp`, `tenacity`, `pydantic`, and `pytest` for testing.

## Changelog

### Version History
| Version | Date | Author | Changes | Status |
|---------|------|--------|---------|--------|
| 1.0 | 03/15/2025 | A. Ogah | Initial version | In Progress |
| 1.1 | 04/01/2025 | TBD | Enhanced monitoring | Planned |
| 1.2 | 04/15/2025 | TBD | Performance optimizations | Planned |
| 2.0 | 05/01/2025 | TBD | Multi-region support | Planned |
| 2.1 | 05/15/2025 | TBD | Advanced analytics | Planned |

### Roadmap
- **Q2 2025**: Multi-region deployment
- **Q3 2025**: Advanced analytics and reporting
- **Q4 2025**: Machine learning-based cost optimization
- **Q1 2026**: Integration with additional AI services

## Support

### Getting Help
- **Documentation**: Review comprehensive documentation in `/docs/`
- **Issues**: Create an issue in this repository
- **Discussions**: Join community discussions
- **Enterprise Support**: Contact enterprise support team

### Community
- **GitHub Discussions**: Community Q&A
- **Stack Overflow**: Technical questions (tag: apim-openai-chargeback)
- **Microsoft Tech Community**: Azure-specific discussions

### Professional Services
- **Implementation Support**: Professional implementation services
- **Training**: Comprehensive training programs
- **Consulting**: Architecture and optimization consulting

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: This solution is designed to integrate seamlessly with existing enterprise AI architectures. Network security groups (NSGs) and enterprise networking parameters should be configured based on your organization's security requirements.

**Disclaimer**: This solution is provided as-is without warranty. Please review and test thoroughly before production deployment.





