import os
import json
import base64
import json
import cv2
import pytesseract
from flask import Flask, request
from google.cloud import storage
from utilities.publisher import publish_message
from utilities.settings import TEXT_PROCESSOR_TRIGGER


app = Flask(__name__)
client_storage = storage.Client()
os.environ["TESSDATA_PREFIX"] = "./tesseract/tessdata"  # '/usr/local/share/tessdata'


def extract_text_from_image(image_path):
    """
    Docstrings

    Args:
        image_path (str): The path to the image file to be checked.
    Returns:

    """
    # Configurables
    oem = 3
    psm = 1
    scale_percent = 40

    image = cv2.imread(image_path)

    # Convert the image to grayscale.
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Resize the image based on the scale percent
    width = int(gray.shape[1] * scale_percent / 100)
    height = int(gray.shape[0] * scale_percent / 100)
    resized = cv2.resize(gray, (width, height), interpolation=cv2.INTER_AREA)

    # Apply thresholding to binarize the image.
    _, thresholded = cv2.threshold(resized, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    custom_config = f"--oem {oem} --psm {psm}"  # Set PSM and OEM
    # Use pytesseract to extract text from the image
    text = pytesseract.image_to_string(thresholded, config=custom_config)

    # Check if the text is empty or contains only whitespace
    return text

def image_handler(pubsub_message):
    pubsub_message_json = json.loads(pubsub_message)
    file_path_blob = pubsub_message_json["file_path"]

    image_bucket = client_storage.get_bucket("ingestion_data_placeholder")
    image_blob = image_bucket.get_blob(file_path_blob)
    file_path = f"/tmp/{file_path_blob.split('/')[-1]}"
    image_blob.download_to_filename(file_path)
    output_text = extract_text_from_image(file_path)
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