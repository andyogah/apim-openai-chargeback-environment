"""
This module integrates Azure Cognitive Search and Azure OpenAI to provide a chat completion service.

The workflow:
1. Retrieves context from Azure Cognitive Search results.
2. Uses the retrieved context to generate a system message for Azure OpenAI.
3. Sends the user question and system message to Azure OpenAI for generating a response.

Ensure the following environment variables are set before running this script:
- AZURE_OPENAI_CHAT_COMPLETION_DEPLOYED_MODEL_NAME: The name of the deployed Azure OpenAI chat completion model.
- Other required Azure Cognitive Search and Azure OpenAI credentials (e.g., API keys, endpoints).

Replace placeholders in the code with your Azure Cognitive Search and Azure OpenAI service details.
"""

import os
from app.auth import AuthenticatorFactory  # Import the authentication module
#from azure.identity import DefaultAzureCredential, get_bearer_token_provider
#from azure.core.credentials import AzureKeyCredential
from openai import AzureOpenAI
from azure.search.documents import SearchClient
import dotenv
from azure.search.documents.models import VectorizedQuery, VectorizableTextQuery

dotenv.load_dotenv()


# Set up authentication
factory = AuthenticatorFactory(auth_type='managed_identity')  # Default to managed identity
authenticator = factory.get_authenticator()
credential = authenticator.get_credential()

# First, let's collect the context from search results
context = ""
for result in search_results:
    context += result["chunk"] + "\n\n"

SYSTEM_MESSAGE = f"""
You are an AI Assistant.
Be brief in your answers. Answer ONLY with the facts listed in the retrieved text.

Context:
{context}
"""

USER_MESSAGE = user_question

response = openai_client.chat.completions.create(
    model=os.getenv("AZURE_OPENAI_CHAT_COMPLETION_DEPLOYED_MODEL_NAME"),
    temperature=0.7,
    messages=[
        {"role": "system", "content": SYSTEM_MESSAGE},
        {"role": "user", "content": USER_MESSAGE},
    ],
)

answer = response.choices[0].message.content
print(answer)