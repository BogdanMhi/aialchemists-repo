import os
import json
import base64
import json
from PIL import Image
from transformers import AutoModelForCausalLM, AutoTokenizer
from flask import Flask, request
from google.cloud import storage
from google.cloud import bigquery
from utilities.publisher import publish_message
from utilities.settings import TEXT_PROCESSOR_TRIGGER, PROJECT_ID, INGESTION_DATA_BUCKET


app = Flask(__name__)
client_storage = storage.Client()
model_id = "vikhyatk/moondream2"
revision = "2024-04-02"
model = AutoModelForCausalLM.from_pretrained(
    model_id, trust_remote_code=True, revision=revision, cache_dir="model_available/"
)
tokenizer = AutoTokenizer.from_pretrained(model_id, revision=revision, cache_dir="model_available/")

bq_client = bigquery.Client(project=PROJECT_ID)

def check_events_duplicates(event_id):
    """
    Check if an event ID already exists in BigQuery table to prevent duplicate processing.

    Args:
        event_id (str): The ID of the event.

    Returns:
        bool: True if the event ID exists, False otherwise.
    """
    table_id = f"{PROJECT_ID}.idempotency.image_handler_msg_ids"
    query = f"SELECT count(message_id) total_rows FROM `{table_id}` WHERE message_id = '{event_id}'"
    results = bq_client.query(query)
    for row in results:
        if row[0]>0:
            return True
        else:
            bq_client.query(f"INSERT INTO `{table_id}` VALUES ('{event_id}')")
            return False
        
def extract_content_from_image(image_path):
    """
    Extract textual content from an image.

    Args:
        image_path (str): The path to the image file.

    Returns:
        str: The extracted textual content from the image.
    """
    image = Image.open(image_path)
    enc_image = model.encode_image(image)
    image_context = model.answer_question(enc_image, "Describe this image.", tokenizer)
    # Check if the text is empty or contains only whitespace
    return image_context

def image_handler(pubsub_message):
    """
    Process images and extract textual content.

    Args:
        pubsub_message (str): The Pub/Sub message containing image information.
    """
    pubsub_message_json = json.loads(pubsub_message)
    file_path_blob = pubsub_message_json["file_path"]

    image_bucket = client_storage.get_bucket(INGESTION_DATA_BUCKET)
    image_blob = image_bucket.get_blob(file_path_blob)
    file_path = f"/tmp/{file_path_blob.split('/')[-1]}"
    image_blob.download_to_filename(file_path)
    output_text = extract_content_from_image(file_path)
    cleaned_output_text = " ".join(output_text.split())

    print(cleaned_output_text)
    output_message = json.dumps({
        "statement": pubsub_message_json["statement"],
        "attachement_output": cleaned_output_text,
        "uuid": pubsub_message_json["uuid"]
        })
    publish_message(TEXT_PROCESSOR_TRIGGER, output_message)

@app.route("/", methods=["POST"])
def index():
    """
    Receive and parse Pub/Sub messages.
    
    This function receives Pub/Sub messages, checks for their validity,
    and processes them if they contain image data.
    """
    envelope = request.get_json()
    if not envelope:
        msg = "no Pub/Sub message received"
        print(f"error: {msg}")
        return f"Bad Request: {msg}", 200

    if not isinstance(envelope, dict) or "message" not in envelope:
        msg = "invalid Pub/Sub message format"
        print(f"error: {msg}")
        return f"Bad Request: {msg}", 200

    pubsub_message = envelope["message"]
    if isinstance(pubsub_message, dict) and "data" in pubsub_message:
        message = base64.b64decode(pubsub_message["data"]).decode("utf-8").strip()
        context = pubsub_message["message_id"]
        if not check_events_duplicates(context):
            image_handler(message)

    return ("", 200)

if __name__ == '__main__':
    app.run()
