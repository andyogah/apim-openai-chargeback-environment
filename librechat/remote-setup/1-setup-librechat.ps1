# File type: PowerShell script (.ps1)
# filepath: 1-setup-librechat.ps1

# LibreChat Initial Setup Script
param(
    [Parameter(Mandatory=$true)]
    [string]$ApimSubscriptionKey,
    
    [Parameter(Mandatory=$true)]
    [string]$ApimEndpoint
)

Write-Host "=== LibreChat Setup - Step 1 ===" -ForegroundColor Green

# Clone LibreChat repository
Write-Host "Cloning LibreChat repository..." -ForegroundColor Yellow
if (Test-Path "LibreChat") {
    Remove-Item -Path "LibreChat" -Recurse -Force
}
git clone https://github.com/danny-avila/LibreChat.git
Set-Location LibreChat

# Copy configuration files
Write-Host "Creating configuration files..." -ForegroundColor Yellow
Copy-Item ".env.example" ".env"
Copy-Item "docker-compose.override.yml.example" "docker-compose.override.yml"
Copy-Item "librechat.example.yaml" "librechat.yaml"

# Update .env file
Write-Host "Configuring .env file..." -ForegroundColor Yellow
$envContent = @"
NODE_ENV=production
HOST=0.0.0.0
PORT=3080
MONGO_URI=mongodb://mongodb:27017/LibreChat

# Azure OpenAI Configuration
ENDPOINTS=azureOpenAI
AZURE_OPENAI_API_KEY=$ApimSubscriptionKey
AZURE_OPENAI_ENDPOINT=$ApimEndpoint
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# Security
JWT_SECRET=$((New-Guid).ToString())
JWT_REFRESH_SECRET=$((New-Guid).ToString())

# Optional: Enable file uploads
ENABLE_UPLOADS=true
"@
$envContent | Out-File -FilePath ".env" -Encoding UTF8

# Update librechat.yaml
Write-Host "Configuring librechat.yaml..." -ForegroundColor Yellow
$librechatConfig = @"
version: 1.0.5
cache: true
endpoints:
  azureOpenAI:
    groups:
      - group: "apim-group"
        apiKey: "`${AZURE_OPENAI_API_KEY}"
        instanceName: "apim-instance"
        apiVersion: "2024-02-15-preview"
        baseURL: "`${AZURE_OPENAI_ENDPOINT}"
        models:
          gpt-4: "gpt-4"
          gpt-35-turbo: "gpt-35-turbo"
          gpt-4-turbo: "gpt-4-turbo"
        titleModel: "gpt-35-turbo"
        dropParams: ["stop", "user", "frequency_penalty", "presence_penalty"]
"@
$librechatConfig | Out-File -FilePath "librechat.yaml" -Encoding UTF8

# Create Dockerfile
Write-Host "Creating Dockerfile..." -ForegroundColor Yellow
$dockerfileContent = @"
FROM node:18-alpine AS base

# Install dependencies
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY api/package*.json ./api/
COPY client/package*.json ./client/
COPY packages/data-provider/package*.json ./packages/data-provider/

# Install dependencies
RUN npm ci --only=production --no-audit

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Create production image
FROM node:18-alpine AS runner
WORKDIR /app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=base --chown=nextjs:nodejs /app .

USER nextjs

EXPOSE 3080

ENV NODE_ENV=production
ENV PORT=3080

CMD ["npm", "start"]
"@
$dockerfileContent | Out-File -FilePath "Dockerfile" -Encoding UTF8

Write-Host "Step 1 completed successfully!" -ForegroundColor Green
Write-Host "Next: Run 2-deploy-infrastructure.ps1" -ForegroundColor Cyan