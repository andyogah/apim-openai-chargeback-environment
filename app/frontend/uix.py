'''Streamlit Frontend for Displaying Aggregated Logs from Quart API'''

import os
import requests
import streamlit as st
import pandas as pd  # For working with tabular data

# Get the port from the environment variable (default to 8501 if not set)
# port = int(os.environ.get("PORT", 8000))

# Set Streamlit to use a wide layout
st.set_page_config(layout="wide")

# Inject custom CSS for font size
st.markdown(
    """
    <style>
    /* Change the background color of the table */
    div[data-testid="stDataFrame"] > div {
        background-color: #f0f8ff; /* Light blue background */
        color: #000000; /* Black text */
    }

    /* Change the header row background and text color */
    .dataframe thead tr th {
        background-color: #4682b4 !important; /* Steel blue background */
        color: white !important; /* White text */
        font-size: 18px !important; /* Adjust header font size */
    }

    /* Change the table body row background and text color */
    .dataframe tbody tr td {
        background-color: #ffffff !important; /* White background */
        color: #000000 !important; /* Black text */
        font-size: 16px !important; /* Adjust body font size */
    }

    /* Add hover effect for rows */
    .dataframe tbody tr:hover {
        background-color: #d3d3d3 !important; /* Light gray on hover */
    }
    </style>
    """,
    unsafe_allow_html=True,
)

# Streamlit App Title
st.title("DOI TOKEN CHARGEBACK VIEWER")

# API Endpoint Configuration
API_URL = os.environ.get("BACKEND_API_URL", "http://localhost:8080/logs")  # Quart API endpoint 
#API_URL = "https://backendapp20250411015503.azurewebsites.net/logs"
#st.write("Environment Variable BACKEND_API_URL:", os.environ.get("BACKEND_API_URL"))
#st.write("Environment Variable BACKEND_API_URL:", API_URL)
#st.write("All Environment Variables:", os.environ)
#st.write("Frontend Hostname:", os.environ.get("WEBSITE_HOSTNAME"))

COLUMN_ORDER = [    
    "subscriptionId",    
    "deploymentId",
    "model",
    "object",
    "promptTokens",
    "completionTokens",
    "totalTokens",    
    "totalCost"    
    ]

# Fetch Data from Quart API
st.subheader("Fetching Logs...")
try:
    # Make a GET request to the Quart API with the Accept header
    headers = {"Accept": "application/json"}
    response = requests.get(API_URL, headers=headers, timeout=30)  # Set timeout to 30 seconds
    # Debug: Display the raw API response
    #st.write("Raw API Response:", response.text)
    response.raise_for_status()  # Raise an HTTPError for bad responses (4xx and 5xx)

    # Debug: Display the raw API response
    #st.write("Raw API Response:", response.text)

    # Parse the JSON response
    logs = response.json()

    # Debug: Display the API response
    # st.write("API Response:", logs)

    # Check if the response contains the expected data
    if "aggregated_logs" in logs and isinstance(logs["aggregated_logs"], list):
        # Convert logs to a DataFrame
        df = pd.DataFrame(logs["aggregated_logs"])

        # Check if all columns in COLUMN_ORDER exist in the DataFrame
        missing_columns = [col for col in COLUMN_ORDER if col not in df.columns]
        if missing_columns:
            st.warning(f"The following columns are missing from the API response: {missing_columns}")

        # Reorder the columns in the DataFrame, filling missing columns with NaN
        df = df.reindex(columns=COLUMN_ORDER)

        # Display the logs in a tabular format
        st.success("Logs fetched successfully!")
        st.subheader("Aggregated Logs")
        st.dataframe(df, height=300, width=2000)  # Use st.dataframe for an interactive table
    else:
        st.error("The API response does not contain valid 'aggregated_logs'. Please check the API.")

except requests.exceptions.ConnectionError:
    st.error("Failed to connect to the API. Ensure the Quart backend is running at the specified URL.")
except requests.exceptions.Timeout:
    st.error("The request to the API timed out. Please try again later.")
except requests.exceptions.HTTPError as http_err:
    st.error(f"HTTP error occurred: {http_err}")
except ValueError:
    st.error("Failed to parse the API response. Ensure the API returns valid JSON.")
except requests.exceptions.RequestException as req_err:
    st.error(f"A request-related error occurred: {req_err}")

# Additional Features
st.sidebar.title("Options")
st.sidebar.write("Use the sidebar to configure additional options.")

# Refresh Button
if st.sidebar.button("Refresh Logs"):
    st.experimental_set_query_params(refresh="true")  # Simulate a refresh by setting query parameters

