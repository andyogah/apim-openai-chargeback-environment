# Usage Examples

This document provides comprehensive examples for integrating with the Azure API Management OpenAI Chargeback Environment across different programming languages and tools.

## Python (Primary)

### Synchronous Usage
```python
import requests

def call_openai_sync():
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
    return response.json()
```

### Asynchronous Usage
```python
import asyncio
import aiohttp

async def call_openai_async():
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
result = asyncio.run(call_openai_async())
```

## C# / .NET {#csharp}

```csharp
using System.Net.Http;
using System.Text;
using System.Text.Json;

public class OpenAIClient
{
    private readonly HttpClient _httpClient;

    public OpenAIClient(string subscriptionKey)
    {
        _httpClient = new HttpClient();
        _httpClient.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", subscriptionKey);
    }

    public async Task<string> CallOpenAI(string message)
    {
        var request = new
        {
            model = "gpt-4",
            messages = new[] { new { role = "user", content = message } }
        };

        var json = JsonSerializer.Serialize(request);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _httpClient.PostAsync(
            "https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions",
            content);

        return await response.Content.ReadAsStringAsync();
    }
}
```

## Node.js {#nodejs}

```javascript
const axios = require('axios');

class OpenAIClient {
    constructor(subscriptionKey) {
        this.subscriptionKey = subscriptionKey;
        this.baseURL = 'https://your-apim-instance.azure-api.net/api/v1/openai';
    }

    async chatCompletion(message) {
        try {
            const response = await axios.post(
                `${this.baseURL}/chat/completions`,
                {
                    model: 'gpt-4',
                    messages: [{ role: 'user', content: message }]
                },
                {
                    headers: {
                        'Ocp-Apim-Subscription-Key': this.subscriptionKey,
                        'Content-Type': 'application/json'
                    }
                }
            );
            return response.data;
        } catch (error) {
            console.error('Error calling OpenAI:', error.response?.data || error.message);
            throw error;
        }
    }
}

// Usage
const client = new OpenAIClient('your-subscription-key');
client.chatCompletion('Hello!').then(console.log);
```

## PowerShell {#powershell}

```powershell
function Invoke-OpenAI {
    param(
        [string]$Message,
        [string]$SubscriptionKey,
        [string]$Model = "gpt-4"
    )

    $headers = @{
        "Ocp-Apim-Subscription-Key" = $SubscriptionKey
        "Content-Type" = "application/json"
    }

    $body = @{
        model = $Model
        messages = @(@{
            role = "user"
            content = $Message
        })
    } | ConvertTo-Json -Depth 3

    $response = Invoke-RestMethod -Uri "https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions" -Method POST -Headers $headers -Body $body
    
    return $response
}

# Usage
$result = Invoke-OpenAI -Message "Hello!" -SubscriptionKey "your-subscription-key"
Write-Output $result
```

## curl {#curl}

### Basic Request
```bash
curl -X POST \
  https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions \
  -H "Ocp-Apim-Subscription-Key: your-subscription-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {
        "role": "user",
        "content": "Hello!"
      }
    ]
  }'
```

### With Error Handling
```bash
#!/bin/bash

SUBSCRIPTION_KEY="your-subscription-key"
API_URL="https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions"

response=$(curl -s -w "%{http_code}" -X POST \
  $API_URL \
  -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -eq 200 ]; then
    echo "Success: $body"
else
    echo "Error $http_code: $body"
fi
```

## Usage Analytics Examples

### Get Usage Summary
```python
import requests

def get_usage_summary(subscription_key, start_date, end_date):
    response = requests.get(
        "https://your-apim-instance.azure-api.net/api/v1/usage/summary",
        headers={"Ocp-Apim-Subscription-Key": subscription_key},
        params={
            "start_date": start_date,
            "end_date": end_date
        }
    )
    return response.json()
```

### Get Chargeback Report
```python
def get_chargeback_report(subscription_key, department=None):
    params = {}
    if department:
        params["department"] = department
    
    response = requests.get(
        "https://your-apim-instance.azure-api.net/api/v1/chargeback/report",
        headers={"Ocp-Apim-Subscription-Key": subscription_key},
        params=params
    )
    return response.json()
```

## Error Handling Examples

### Python with Retry Logic
```python
import requests
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
def call_openai_with_retry(message, subscription_key):
    response = requests.post(
        "https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions",
        headers={
            "Ocp-Apim-Subscription-Key": subscription_key,
            "Content-Type": "application/json"
        },
        json={
            "model": "gpt-4",
            "messages": [{"role": "user", "content": message}]
        },
        timeout=30
    )
    response.raise_for_status()
    return response.json()
```

### Node.js with Circuit Breaker
```javascript
const CircuitBreaker = require('opossum');
const axios = require('axios');

const options = {
    timeout: 30000,
    errorThresholdPercentage: 50,
    resetTimeout: 30000
};

const callOpenAI = async (message, subscriptionKey) => {
    const response = await axios.post(
        'https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions',
        {
            model: 'gpt-4',
            messages: [{ role: 'user', content: message }]
        },
        {
            headers: {
                'Ocp-Apim-Subscription-Key': subscriptionKey,
                'Content-Type': 'application/json'
            }
        }
    );
    return response.data;
};

const breaker = new CircuitBreaker(callOpenAI, options);
breaker.fallback(() => ({ error: 'Service temporarily unavailable' }));

// Usage
breaker.fire('Hello!', 'your-subscription-key')
    .then(console.log)
    .catch(console.error);
```

## Streaming Examples

### Python Streaming
```python
import requests
import json

def stream_openai_response(message, subscription_key):
    response = requests.post(
        "https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions",
        headers={
            "Ocp-Apim-Subscription-Key": subscription_key,
            "Content-Type": "application/json"
        },
        json={
            "model": "gpt-4",
            "messages": [{"role": "user", "content": message}],
            "stream": True
        },
        stream=True
    )
    
    for line in response.iter_lines():
        if line:
            line = line.decode('utf-8')
            if line.startswith('data: '):
                data = line[6:]
                if data != '[DONE]':
                    chunk = json.loads(data)
                    if 'choices' in chunk and chunk['choices']:
                        delta = chunk['choices'][0].get('delta', {})
                        if 'content' in delta:
                            yield delta['content']
```

## Testing Examples

### Unit Test Example
```python
import pytest
import requests_mock
from your_module import OpenAIClient

def test_openai_client_success():
    with requests_mock.Mocker() as m:
        m.post(
            'https://your-apim-instance.azure-api.net/api/v1/openai/chat/completions',
            json={
                'choices': [{'message': {'content': 'Hello back!'}}]
            }
        )
        
        client = OpenAIClient('test-key')
        result = client.chat_completion('Hello!')
        
        assert 'choices' in result
        assert result['choices'][0]['message']['content'] == 'Hello back!'
```

### Integration Test Example
```python
import pytest
import os
from your_module import OpenAIClient

@pytest.mark.integration
def test_openai_integration():
    subscription_key = os.environ.get('APIM_SUBSCRIPTION_KEY')
    if not subscription_key:
        pytest.skip('APIM_SUBSCRIPTION_KEY not set')
    
    client = OpenAIClient(subscription_key)
    result = client.chat_completion('Say hello')
    
    assert 'choices' in result
    assert len(result['choices']) > 0
```
