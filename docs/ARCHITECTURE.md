# Architecture Documentation

## System Architecture Overview

This document provides detailed architectural information for the Azure API Management OpenAI Chargeback Environment solution.

## High-Level Architecture

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

## Detailed Component Architecture

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

## Architecture Principles

### Design Principles
- **Scalability**: Handle increasing loads gracefully through auto-scaling
- **Reliability**: 99.9% uptime target with multi-region support
- **Security**: Defense in depth approach with encryption and RBAC
- **Cost Optimization**: Efficient resource utilization with right-sizing
- **Maintainability**: Clean, well-documented code with comprehensive testing

### Technology Stack
- **Cloud Platform**: Microsoft Azure
- **Infrastructure**: Bicep (primary), Terraform, ARM templates (alternatives)
- **API Gateway**: Azure API Management
- **Compute**: Azure Functions (Python 3.9+)
- **Storage**: Redis Cache, Cosmos DB, Blob Storage
- **Monitoring**: Application Insights, Log Analytics, Azure Monitor
- **Security**: Azure Key Vault, Azure AD

## Component Deep Dive

### API Management Layer
- **Purpose**: Gateway, security, and policy enforcement
- **Features**: 
  - Rate limiting and throttling
  - Authentication and authorization
  - Request/response transformation
  - Custom logging and monitoring
- **Scaling**: Auto-scaling based on demand
- **Security**: OAuth 2.0, API keys, IP filtering, CORS policies

### Function App Layer (Python)
- **Purpose**: Business logic and chargeback processing
- **Functions**:
  - `usage_tracking/` - Real-time usage monitoring
  - `chargeback_calculation/` - Cost calculation engine
  - `cost_allocation/` - Department/user cost allocation
  - `report_generation/` - Automated report creation
- **Scaling**: Consumption plan with automatic scaling
- **Performance**: Sub-second response times with async processing

### Storage Layer
- **Redis Cache**: 
  - Session data and temporary storage
  - High-performance caching layer
  - TTL-based data expiration
- **Cosmos DB**: 
  - Long-term usage data storage
  - Global distribution capabilities
  - Automatic scaling
- **Blob Storage**: 
  - Report and backup storage
  - Lifecycle management policies
  - Cost-effective long-term storage
- **Key Vault**: 
  - Secrets and certificates management
  - Managed identity integration
  - Audit logging

## Data Flow Architecture

### Request Processing Flow
```
1. Client Application
   ↓ (HTTP/HTTPS Request)
2. Azure API Management
   ↓ (Policy Processing & Authentication)
3. Azure Functions (Python)
   ↓ (Payload Processing & Usage Tracking)
4. Azure OpenAI Service
   ↓ (AI Processing)
5. Azure Functions (Python)
   ↓ (Response Processing & Cost Calculation)
6. Redis Cache
   ↓ (Usage Data Storage)
7. Azure API Management
   ↓ (Response Policies)
8. Client Application
```

### Chargeback Processing Flow
```
1. Usage Data Collection (Redis)
   ↓ (Batch Processing - Every 15 minutes)
2. Azure Functions (Cost Calculation)
   ↓ (Aggregation & Analysis)
3. Azure Cosmos DB (Long-term Storage)
   ↓ (Report Generation)
4. Azure Blob Storage (Report Storage)
   ↓ (Dashboard Integration)
5. Monitoring Dashboards
```

## Security Architecture

### Authentication Flow
```
1. Client Request with API Key/Token
   ↓
2. APIM Authentication Policy
   ↓ (Azure AD Integration)
3. Token Validation
   ↓ (RBAC Check)
4. Function App Authorization
   ↓ (Resource Access)
5. Azure Services Access
```

### Data Protection
- **Encryption at Rest**: All storage services encrypted
- **Encryption in Transit**: TLS 1.2+ for all communications
- **Minimal Data Retention**: Configurable retention policies
- **Audit Logging**: Comprehensive activity tracking
- **Network Security**: Private endpoints, NSG rules, firewalls

## Deployment Architecture

### Multi-Environment Strategy
```
Development Environment:
├── Single region deployment
├── Basic monitoring setup
├── Development SKUs
└── Reduced redundancy

Staging Environment:
├── Multi-region deployment
├── Full monitoring setup
├── Production-like SKUs
└── Performance testing

Production Environment:
├── Multi-region deployment
├── High availability configuration
├── Production SKUs
├── Full monitoring & alerting
├── Backup & disaster recovery
└── Enterprise security controls
```

### CI/CD Pipeline Architecture
```
Source Control (Git)
↓
Build Pipeline
├── Code Quality Checks
├── Security Scanning
├── Unit Testing
└── Package Creation
↓
Infrastructure Pipeline
├── Bicep/Terraform Validation
├── What-if Analysis
├── Infrastructure Deployment
└── Configuration Updates
↓
Application Pipeline
├── Function App Deployment
├── APIM Policy Updates
├── Integration Testing
└── Health Checks
↓
Monitoring & Validation
├── Performance Testing
├── Security Validation
└── End-to-End Testing
```

## Scalability Patterns

### Auto-Scaling Configuration
- **Function App**: Consumption plan scales 0-200 instances
- **APIM**: Auto-scales based on request volume
- **Redis Cache**: Manual scaling with monitoring alerts
- **Cosmos DB**: Automatic scaling based on RU consumption

### Performance Optimization
- **Connection Pooling**: Efficient database connections
- **Caching Strategy**: Multi-level caching implementation
- **Async Processing**: Non-blocking operations
- **Load Balancing**: Traffic distribution across regions

## Monitoring & Observability

### Monitoring Architecture
```
Application Layer
├── Azure Functions (Application Insights)
├── Custom Metrics & Telemetry
└── Performance Counters

Infrastructure Layer
├── Azure Monitor (Resource Metrics)
├── Log Analytics (Centralized Logging)
└── Network Watcher (Network Diagnostics)

Business Layer
├── Cost Management (Usage & Billing)
├── Chargeback Reports (Business Metrics)
└── SLA Monitoring (Availability & Performance)
```

### Key Metrics
- **Performance**: API request volume, latency, throughput
- **Usage**: OpenAI token consumption, model usage patterns
- **Reliability**: Error rates, availability, failure patterns
- **Efficiency**: Cache hit/miss ratios, resource utilization
- **Cost**: Real-time cost tracking, budget alerts

## Disaster Recovery & Business Continuity

### Multi-Region Architecture
```
Primary Region (East US)
├── Full deployment
├── Active traffic handling
└── Data replication

Secondary Region (West Europe)
├── Standby deployment
├── Data synchronization
└── Automated failover
```

### Backup Strategy
- **Configuration Backup**: IaC templates in source control
- **Data Backup**: Automated Cosmos DB backups
- **State Backup**: Redis persistence and snapshots
- **Application Backup**: Function App deployment packages
