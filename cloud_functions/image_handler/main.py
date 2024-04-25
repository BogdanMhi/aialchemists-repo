import os
import json
import base64
# import shutil
# import tempfile
# import time
# import concurrent.futures

import json
import cv2
import pytesseract
from google.cloud import storage
import functions_framework
from utilities.publisher import publish_message
from utilities.settings import TEXT_PROCESSOR_TRIGGER


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


# Triggered from a message on a Cloud Pub/Sub topic.

client_storage = storage.Client()

@functions_framework.cloud_event
def image_handler(cloud_event):
    # Print out the data from Pub/Sub, to prove that it worked
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
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