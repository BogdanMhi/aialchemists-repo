import os

# General
PROJECT_ID = os.environ.get("PROJECT_ID")

# Firestore
FIRESTORE_DATABASE_ID = os.environ.get("FIRESTORE_DATABASE_ID")
HISTORY_COLLECTION = os.environ.get("HISTORY_COLLECTION")

# Azure
AZURE_OPENAI_API_KEY = os.environ.get("AZURE_OPENAI_API_KEY")
AZURE_OPENAI_ENDPOINT = os.environ.get("AZURE_OPENAI_ENDPOINT")

# BigQuery
BIGQUERY_DATABASE_ID = os.environ.get("BIGQUERY_DATABASE_ID")

# FE
FE_APP_NAME = os.environ.get("FE_APP_NAME")