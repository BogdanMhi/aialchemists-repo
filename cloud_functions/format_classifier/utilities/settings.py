import os

# General
PROJECT_ID = os.environ.get("PROJECT_ID")

# Pub/Sub
DOCUMENT_HANDLER_TRIGGER = os.environ.get("DOCUMENT_HANDLER_TRIGGER")
IMAGE_HANDLER_TRIGGER = os.environ.get("IMAGE_HANDLER_TRIGGER")
IOT_HANDLER_TRIGGER = os.environ.get("IOT_HANDLER_TRIGGER")
TEXT_PROCESSOR_TRIGGER = os.environ.get("TEXT_PROCESSOR_TRIGGER")
VIDEO_HANDLER_TRIGGER = os.environ.get("VIDEO_HANDLER_TRIGGER")

# Cloud Storage
INGESTION_DATA_BUCKET = os.environ.get("INGESTION_DATA_BUCKET")