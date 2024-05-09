import os

# General
PROJECT_ID = os.environ.get("PROJECT_ID")

# Pub/Sub
TEXT_PROCESSOR_TRIGGER = os.environ.get("TEXT_PROCESSOR_TRIGGER")

# Firestore
FIRESTORE_DATABASE_ID = os.environ.get("FIRESTORE_DATABASE_ID")

# Cloud Storage
INGESTION_DATA_BUCKET = os.environ.get("INGESTION_DATA_BUCKET")