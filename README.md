# Azure API Management OpenAI Chargeback Environment

A comprehensive solution for implementing scalable OpenAI usage tracking and chargeback mechanisms through Azure API Management, addressing payload size limitations and data persistence concerns.

## Table of Contents
- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Solution Architecture](#solution-architecture)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Usage](#usage)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Contributing](#contributing)
- [Changelog](#changelog)

## Overview

### What
This repository provides a complete Infrastructure-as-Code (IaC) solution for implementing OpenAI usage chargeback in enterprise environments using Azure API Management. The solution addresses scalability challenges and data persistence concerns while providing comprehensive usage tracking and billing capabilities.

### Why
- **Payload Size Limitations**: Azure APIM Diagnostic Logs have an 8192-byte limit for Log Analytics Workspaces, causing truncation of larger payloads
- **Data Privacy Concerns**: Organizations need flexible data retention policies and minimal data persistence for security compliance
- **Cost Management**: Enterprises require detailed usage tracking and chargeback mechanisms for OpenAI services
- **Scalability**: Need for handling both streaming and batch data processing scenarios

### Who (Audience)
- **Primary**: Enterprise Azure architects and DevOps engineers
- **Secondary**: Security teams, Cost management teams, AI/ML platform teams
- **Tertiary**: Compliance officers and data governance teams

### When
- **Initial Release**: March 15, 2025
- **Target Deployment**: Production-ready for enterprise environments
- **Maintenance**: Ongoing updates based on Azure service evolution

### Where
- **Cloud Platform**: Microsoft Azure
- **Deployment Regions**: Multi-region capable
- **Network Integration**: Enterprise network-ready with NSG compatibility

## Problem Statement

### Current Challenges
1. **Log Size Limitations**: APIM Diagnostic Logs truncate at 8192 bytes, insufficient for large OpenAI payloads
2. **Data Persistence**: Security requirements demand minimal data retention with flexible policies
3. **Scalability**: Need to handle varying data volumes and formats
4. **Cost Tracking**: Lack of granular usage tracking and chargeback mechanisms

### Technical Requirements
- Handle streaming and batch data processing
- Support various natural language data formats
- Provide data veracity and validation
- Deliver actionable chargeback insights
- Maintain low operational costs
- Ensure high maintainability and reproducibility
- Enable automated workflows

## Solution Architecture

### Core Components
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

### Azure Resources
- **Azure OpenAI**: Core AI service endpoint
- **Azure API Management**: Gateway and policy enforcement
- **Azure Functions**: Serverless processing and chargeback logic
- **Azure Cache for Redis**: Temporary data storage and session management
- **Azure Key Vault**: Secure credential management (optional)
- **Log Analytics Workspace**: Monitoring and diagnostics (optional)

## Getting Started

### Prerequisites
- Azure subscription with appropriate permissions
- Azure CLI or PowerShell
- Docker Desktop (for local LibreChat instance)
- Terraform or ARM templates (for IaC deployment)

### Quick Start
1. Clone the repository
2. Configure environment variables
3. Deploy infrastructure using provided IaC templates
4. Configure APIM policies
5. Set up monitoring and alerting

## Deployment

### Infrastructure Deployment
```bash
# Navigate to infrastructure directory
cd infrastructure/

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="environments/dev.tfvars"

# Apply configuration
terraform apply -var-file="environments/dev.tfvars"
```

### APIM Policy Configuration
The solution includes custom APIM policies for:
- Request/response logging
- Usage tracking
- Rate limiting
- Authentication/authorization
- Payload size management

### Function App Deployment
Automated deployment through Azure DevOps pipelines or GitHub Actions.

## Usage

### Chargeback Data Example
The solution provides detailed usage tracking as shown below:

![Example of chargeback table](app/backend/example-log-chargeback.png)

### API Endpoints
- `POST /api/v1/openai/chat/completions` - OpenAI chat completions
- `GET /api/v1/usage/summary` - Usage summary
- `GET /api/v1/chargeback/report` - Chargeback report

### Monitoring Dashboard
Access real-time usage metrics through Azure Monitor workbooks and custom dashboards.

## Configuration

### Environment Variables
```bash
AZURE_OPENAI_ENDPOINT=https://your-openai-instance.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key
REDIS_CONNECTION_STRING=your-redis-connection-string
APIM_SUBSCRIPTION_KEY=your-apim-subscription-key
```

### APIM Policies
Configuration files located in `/policies/` directory:
- `inbound-policy.xml` - Request processing
- `outbound-policy.xml` - Response processing
- `on-error-policy.xml` - Error handling

## Monitoring

### Key Metrics
- API request volume and latency
- OpenAI token usage and costs
- Error rates and failure patterns
- Cache hit/miss ratios
- Function execution metrics

### Alerting
Configured alerts for:
- High API usage
- Error rate thresholds
- Cost anomalies
- Performance degradation

## Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch
3. Implement changes with tests
4. Submit pull request
5. Code review and approval

### Testing
- Unit tests for Function App logic
- Integration tests for APIM policies
- End-to-end testing with LibreChat

## Changelog

### Version History
| Version | Date | Author | Changes | Status |
|---------|------|--------|---------|--------|
| 1.0 | 03/15/2025 | A. Ogah | Initial version | In Progress |
| 1.1 | TBD | TBD | Enhanced monitoring | Planned |
| 2.0 | TBD | TBD | Multi-region support | Planned |

## Support

For questions, issues, or contributions:
- Create an issue in this repository
- Contact the development team
- Review documentation in `/docs/` directory

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This solution is designed to integrate seamlessly with existing enterprise AI architectures. Network security groups (NSGs) and enterprise networking parameters should be configured based on your organization's security requirements.





