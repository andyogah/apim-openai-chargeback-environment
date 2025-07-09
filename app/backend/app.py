"""
This module defines a Quart application that fetches log data from Redis,
processes it, structures it into an HTML table, and calculates the chargeback code.

The application includes:
- An endpoint to fetch and process log data from Redis.
- An endpoint to calculate the chargeback based on the log data.
- A WebSocket endpoint to stream new logs from Redis in real-time.

The Redis connection is established using managed identity for secure access.
"""

import json
import os
import logging
from quart import Quart, jsonify, websocket, render_template, request
import redis.asyncio as redis
from azure.identity.aio import DefaultAzureCredential
from azure.mgmt.redis.aio import RedisManagementClient
#from dotenv import load_dotenv

# Load environment variables from .env file
#load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

app = Quart(__name__)

class RedisClientManager:
    """Manages the Redis client instance."""
    _redis_client = None
    _credential = None
    _redis_mgmt_client = None

    @classmethod
    async def get_redis_client(cls):
        """Initialize Redis connection using Managed Identity."""
        if cls._redis_client is None:
            try:
                credential = DefaultAzureCredential()
                subscription_id = os.environ["AZURE_SUBSCRIPTION_ID"]
                resource_group_name = os.environ["AZURE_RESOURCE_GROUP"]
                redis_name = os.environ["REDIS_NAME"]

                # Create a Redis management client
                redis_mgmt_client = RedisManagementClient(credential, subscription_id)

                # Retrieve the Redis keys
                keys = await redis_mgmt_client.redis.list_keys(resource_group_name, redis_name)
                primary_key = keys.primary_key

                redis_host = os.environ["Redis__redisHostName"]

                cls._redis_client = redis.from_url(
                    f"rediss://{redis_host}:6380",
                    password=primary_key,
                    decode_responses=True
                )
                logging.info("Successfully connected to Redis using Managed Identity")
            except Exception as e:
                logging.error("Failed to connect to Redis: %s", e)
                raise
        return cls._redis_client

    @classmethod
    async def close_redis_client(cls):
        """Close the Redis client."""
        if cls._redis_client:
            await cls._redis_client.close()
            cls._redis_client = None
            logging.info("Redis client closed")

        if cls._redis_mgmt_client:
            await cls._redis_mgmt_client.close()
            cls._redis_mgmt_client = None
            logging.info("Redis management client closed")

        if cls._credential:
            await cls._credential.close()
            cls._credential = None
            logging.info("Azure credential closed")

@app.before_serving
async def startup():
    """Startup tasks for the Quart app."""
    await RedisClientManager.get_redis_client()  # Ensure Redis client is initialized

@app.after_serving
async def shutdown():
    """Shutdown tasks for the Quart app."""
    await RedisClientManager.close_redis_client()

def calculate_chargeback(log_data):
    """Calculate the chargeback based on the log data."""
    deployment_id = log_data.get("deploymentId")
    prompt_tokens = log_data.get("promptTokens", 0)
    completion_tokens = log_data.get("completionTokens", 0)
    image_tokens = log_data.get("imageTokens", 0)

    # Calculate costs based on Deployment ID and Token Type
    prompt_token_cost = 0.0
    completion_token_cost = 0.0
    image_token_cost = 0.0

    if deployment_id == "gpt-4o":
        prompt_token_cost = prompt_tokens / 1000 * 0.03
        completion_token_cost = completion_tokens / 1000 * 0.06
    elif deployment_id == "gpt-4":
        prompt_token_cost = prompt_tokens / 1000 * 0.02
        completion_token_cost = completion_tokens / 1000 * 0.05
    elif deployment_id == "gpt-35-turbo":
        prompt_token_cost = prompt_tokens / 1000 * 0.0015
        completion_token_cost = completion_tokens / 1000 * 0.002
    elif deployment_id == "gpt-35-turbo-instruct":
        prompt_token_cost = prompt_tokens / 1000 * 0.0018
        completion_token_cost = completion_tokens / 1000 * 0.0025
    elif deployment_id == "text-embedding-3-large":
        prompt_token_cost = prompt_tokens / 1000 * 0.001
        completion_token_cost = completion_tokens / 1000 * 0.002
    elif deployment_id == "dall-e-3":
        image_token_cost = image_tokens / 1000 * 0.009

    total_cost = round(prompt_token_cost + completion_token_cost + image_token_cost, 2)
    return total_cost


@app.route("/logs", methods=["GET"])
async def get_logs():
    """
    Endpoint to fetch and process log data from Redis.
    Returns JSON data for the frontend to consume.
    """
    try:
        redis_client = await RedisClientManager.get_redis_client()
        keys = await redis_client.keys('*')  # Fetch all keys
        logging.info(f"Fetched keys from Redis: {keys}")

        if not keys:
            logging.warning("No keys found in Redis")
            return jsonify({"aggregated_logs": []})

        processed_logs = []
        for key in keys:
            log = await redis_client.get(key)  # Fetch log data for each key
            if log:
                try:
                    log_data = json.loads(log)  # Convert string data back to dict
                    log_data["totalCost"] = f"{calculate_chargeback(log_data):.2f}"  # Format total cost
                    processed_logs.append(log_data)
                except json.JSONDecodeError as e:
                    logging.error(f"Failed to decode log for key {key}: {e}")

        # Return JSON response
        response = {
            "aggregated_logs": processed_logs
        }
        return jsonify(response)

    except Exception as e:
        logging.error(f"Error in /logs endpoint: {e}")
        return jsonify({"error": "Failed to fetch logs"}), 500

@app.route("/chargeback", methods=["GET"])
async def get_chargeback():
    """Endpoint to fetch and process log data from Redis, and calculate the chargeback."""
    try:
        redis_client = await RedisClientManager.get_redis_client()
        keys = await redis_client.keys('*')  # Fetch all keys
        logging.info(f"Fetched keys from Redis: {keys}")

        total_chargeback = 0
        processed_logs = []
        for key in keys:
            log = await redis_client.get(key)  # Fetch log data for each key
            log_data = json.loads(log)  # Convert string data back to dict
            total_chargeback += calculate_chargeback(log_data)
            log_data["totalCost"] = f"{calculate_chargeback(log_data):.2f}"  # Format total cost
            processed_logs.append(log_data)

        response = {
            "totalChargeback": f"{total_chargeback:.2f}",  # Format total chargeback
            "logs": processed_logs,
        }

        return jsonify(response)

    except Exception as e:
        logging.error(f"Error in /chargeback endpoint: {e}")
        return jsonify({"error": "Failed to calculate chargeback"}), 500

@app.websocket("/ws/logs")
async def logs_websocket():
    """WebSocket endpoint to stream new logs."""
    redis_client = await RedisClientManager.get_redis_client()
    while True:
        log = await redis_client.brpop("logs")  # Blocking call to wait for a new log
        await websocket.send(log[1])  # Send log data to frontend


