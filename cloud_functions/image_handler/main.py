import os
import json
import base64
import json
from PIL import Image
from transformers import AutoModelForCausalLM, AutoTokenizer
from flask import Flask, request
from google.cloud import storage
from utilities.publisher import publish_message
from utilities.settings import TEXT_PROCESSOR_TRIGGER


app = Flask(__name__)
client_storage = storage.Client()
model_id = "vikhyatk/moondream2"
revision = "2024-04-02"
model = AutoModelForCausalLM.from_pretrained(
    model_id, trust_remote_code=True, revision=revision
)
tokenizer = AutoTokenizer.from_pretrained(model_id, revision=revision)



def extract_content_from_image(image_path):
    """
    Docstrings

    Args:
        image_path (str): The path to the image file to be checked.
    Returns:

    """
    image = Image.open(image_path)
    enc_image = model.encode_image(image)
    image_context = model.answer_question(enc_image, "Describe this image.", tokenizer)
    # Check if the text is empty or contains only whitespace
    return image_context

def image_handler(pubsub_message):
    pubsub_message_json = json.loads(pubsub_message)
    file_path_blob = pubsub_message_json["file_path"]

    image_bucket = client_storage.get_bucket("ingestion_data_placeholder")
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
    """Receive and parse Pub/Sub messages."""
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
        image_handler(message)

    return ("", 200)

if __name__ == '__main__':
    app.run()