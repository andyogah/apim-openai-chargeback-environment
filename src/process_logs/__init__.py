"""
Azure Function to process log data and store it in Redis.

This function is triggered by HTTP request hitting the APIM, recieves 
the HTTP request with log data, processes the data, and stores it in Redis
for 24 hours. If there is existing data for the same composite subscription
and deployment key, it updates the existing data with an increment of the new
values.

The function also logs the stored data to the function app's log stream.
"""

import logging
import json
import os
import redis
from azure.identity import DefaultAzureCredential
from azure.mgmt.redis import RedisManagementClient
import azure.functions as func

def get_redis_client():
    """Initialize Redis connection using Managed Identity."""
    try:
        credential = DefaultAzureCredential()
        subscription_id = os.environ["AZURE_SUBSCRIPTION_ID"]
        resource_group_name = os.environ["AZURE_RESOURCE_GROUP"]
        redis_name = os.environ["REDIS_NAME"]

        # Create a Redis management client
        redis_mgmt_client = RedisManagementClient(credential, subscription_id)

        # Retrieve the Redis keys
        keys = redis_mgmt_client.redis.list_keys(resource_group_name, redis_name)
        primary_key = keys.primary_key

        redis_host = os.environ["Redis__redisHostName"]

        redis_client = redis.StrictRedis(
            host=redis_host,
            port=6380,  # Default SSL port for Redis
            ssl=True,
            password=primary_key
        )
        logging.info("Successfully connected to Redis using Managed Identity")
        return redis_client
    except Exception as e:
        logging.error("Failed to connect to Redis: %s", e)
        raise

def parse_request(req):
    """Parse the HTTP request and extract necessary fields."""
    try:
        # req_body = req.get_json()
        # logging.info("Request payload: %s", json.dumps(req_body, indent=2))
        raw_body = req.get_body().decode('utf-8')
        logging.info("Raw request body: %s", raw_body)
        req_body = json.loads(raw_body)
        logging.info("Request payload: %s", json.dumps(req_body, indent=2))
    except ValueError:
        logging.error("Invalid request body")
        return None, "Invalid request body", 400

    subscription_id = req_body.get("subscriptionId")
    deployment_id = req_body.get("deploymentId")
    response_body = req_body.get("responseBody", {})
    model = response_body.get("model")
    object_type = response_body.get("object")
    usage = response_body.get("usage", {})
    completion_tokens = usage.get("completion_tokens", 0)
    prompt_tokens = usage.get("prompt_tokens", 0)
    total_tokens = usage.get("total_tokens", 0)

    if not all([subscription_id, deployment_id, model, object_type]):
        logging.error("Missing required fields")
        return None, "Missing required fields", 400

    log_data = {
        "subscriptionId": subscription_id,
        "deploymentId": deployment_id,
        "model": model,
        "object": object_type,
        "completionTokens": completion_tokens,
        "promptTokens": prompt_tokens,
        "totalTokens": total_tokens,
    }

    return log_data, None, None

def update_redis_cache(redis_client, cache_key, log_data):
    """Update the Redis cache with the new log data."""
    try:
        existing_value = redis_client.get(cache_key)
        if existing_value:
            existing_data = json.loads(existing_value)
            log_data["completionTokens"] += existing_data.get("completionTokens", 0)
            log_data["promptTokens"] += existing_data.get("promptTokens", 0)
            log_data["totalTokens"] += existing_data.get("totalTokens", 0)

        cache_value = json.dumps(log_data)
        redis_client.setex(cache_key, 86400, cache_value)
        logging.info("Data cached in Redis successfully")
        logging.info(f"Cache key: {cache_key}")
        logging.info(f"Cache value: {cache_value}")
    except redis.RedisError as e:
        logging.error("Failed to interact with Redis: %s", e)
        return "Failed to process log data", 500

    return None, None

def main(req: func.HttpRequest) -> func.HttpResponse:
    """Main function to process the HTTP request, store log data in Redis, and log the stored data."""
    logging.info("Python HTTP trigger function processed a request.")

    # Calculate the size of the request payload and headers
    request_payload_size = len(req.get_body())
    request_headers_size = sum(len(k) + len(v) for k, v in req.headers.items())
    total_request_size = request_payload_size + request_headers_size

    logging.info(f"Request payload size: {request_payload_size} bytes")
    logging.info(f"Request headers size: {request_headers_size} bytes")
    logging.info(f"Total request size: {total_request_size} bytes")

    log_data, error_message, status_code = parse_request(req)
    if error_message:
        return func.HttpResponse(error_message, status_code=status_code)

    redis_client = get_redis_client()
    cache_key = f"{log_data['subscriptionId']}-{log_data['deploymentId']}"

    error_message, status_code = update_redis_cache(redis_client, cache_key, log_data)
    if error_message:
        return func.HttpResponse(error_message, status_code=status_code)

    # Calculate the size of the response payload and headers
    response_payload = json.dumps(log_data).encode('utf-8')
    response_payload_size = len(response_payload)
    response_headers = {
        "Content-Type": "application/json",
        "Content-Length": str(response_payload_size)
    }
    response_headers_size = sum(len(k) + len(v) for k, v in response_headers.items())
    total_response_size = response_payload_size + response_headers_size

    logging.info(f"Response payload size: {response_payload_size} bytes")
    logging.info(f"Response headers size: {response_headers_size} bytes")
    logging.info(f"Total response size: {total_response_size} bytes")

    # Log the total size (request + response)
    total_size = total_request_size + total_response_size
    logging.info(f"Total size (request + response): {total_size} bytes")

    # Log the stored data to the function app's log stream
    logging.info("Stored log data: %s", json.dumps(log_data, indent=2))
    return func.HttpResponse("Log data processed and stored successfully", status_code=200)