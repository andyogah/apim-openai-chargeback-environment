# Contributing Guidelines

## Welcome Contributors!

Thank you for your interest in contributing to the Azure API Management OpenAI Chargeback Environment project.

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Issues
- Use the GitHub issue tracker
- Provide detailed reproduction steps
- Include environment information
- Attach relevant logs or screenshots

### Suggesting Enhancements
- Open an issue with the "enhancement" label
- Provide clear use cases
- Include implementation suggestions
- Consider backward compatibility

### Contributing Code
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

## Development Setup

### Prerequisites
- Python 3.9+
- Azure CLI
- Azure Functions Core Tools v4.x
- Bicep CLI (primary) or Terraform (alternative)
- Docker Desktop
- VS Code with Python extension (recommended)

### Local Development
```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/apim-openai-chargeback-environment.git

# Navigate to Function App
cd function-app

# Create virtual environment
python -m venv venv

# Activate virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install development dependencies
pip install -r requirements-dev.txt

# Set up environment
cp local.settings.json.example local.settings.json
# Edit local.settings.json with your values

# Run tests
python -m pytest

# Run locally
func start
```

## Pull Request Process

### Before Submitting
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Code follows style guidelines
- [ ] Commit messages are clear

### PR Requirements
- Clear description of changes
- Link to related issues
- Screenshots for UI changes
- Breaking change notifications

## Testing Guidelines

### Test Categories
- Unit tests for individual functions
- Integration tests for component interactions
- End-to-end tests for workflows
- Performance tests for scalability

### Test Commands
```bash
# Run all tests
cd function-app
python -m pytest

# Run specific test types
python -m pytest -m unit
python -m pytest -m integration
python -m pytest -m e2e

# Run with coverage
python -m pytest --cov=. --cov-report=html --cov-report=term

# Run linting
flake8 .
black --check .
isort --check-only .

# Format code
black .
isort .
```

## Code Quality Standards

### Python Code Standards
- Follow PEP 8 style guide
- Use type hints for function parameters and return values
- Maximum line length: 88 characters (Black formatter)
- Use docstrings for all public functions and classes

### Function App Structure
```python
"""
Usage tracking function for OpenAI API calls.
"""
import logging
from typing import Dict, Any, Optional
import azure.functions as func
from azure.functions import HttpRequest, HttpResponse


async def main(req: HttpRequest) -> HttpResponse:
    """
    Tracks usage for OpenAI API calls and calculates costs.
    
    Args:
        req: HTTP request containing usage data
        
    Returns:
        HTTP response with calculated cost information
        
    Raises:
        ValueError: If usage data is invalid
        ConnectionError: If Redis cache is unavailable
    """
    logging.info('Processing usage tracking request')
    
    try:
        # Implementation
        return func.HttpResponse(
            body=result,
            status_code=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        logging.error(f"Error processing request: {str(e)}")
        return func.HttpResponse(
            body=f"Error: {str(e)}",
            status_code=500
        )
```

### Testing Standards
```python
"""
Unit tests for usage tracking function.
"""
import pytest
import asyncio
from unittest.mock import Mock, patch
from function_app import main


class TestUsageTracking:
    """Test cases for usage tracking functionality."""
    
    @pytest.mark.asyncio
    async def test_valid_usage_data(self):
        """Test processing valid usage data."""
        # Test implementation
        pass
    
    @pytest.mark.asyncio
    async def test_invalid_usage_data(self):
        """Test handling invalid usage data."""
        # Test implementation
        pass
    
    @pytest.mark.integration
    async def test_redis_integration(self):
        """Test Redis cache integration."""
        # Test implementation
        pass
```

## Documentation Standards

### Code Documentation
- Use docstrings for all public functions, classes, and modules
- Include type hints for better IDE support
- Document complex algorithms and business logic
- Provide usage examples in docstrings

### Requirements Files
Maintain separate requirements files:
- `requirements.txt` - Production dependencies
- `requirements-dev.txt` - Development dependencies
- `requirements-test.txt` - Testing dependencies

### Example requirements.txt
```txt
azure-functions>=1.18.0
azure-cosmos>=4.5.0
redis>=5.0.0
aiohttp>=3.8.0
tenacity>=8.2.0
pydantic>=2.0.0
python-dotenv>=1.0.0
```

### Example requirements-dev.txt
```txt
pytest>=7.0.0
pytest-asyncio>=0.21.0
pytest-cov>=4.0.0
black>=23.0.0
flake8>=6.0.0
isort>=5.12.0
mypy>=1.0.0
```

## Review Process

### Code Review
- All code changes require review
- Address reviewer feedback
- Maintain code quality standards
- Ensure security best practices

### Approval Process
- Maintainer approval required
- Automated tests must pass
- Documentation must be updated
- No merge conflicts

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project documentation
- Community highlights

Thank you for contributing!
