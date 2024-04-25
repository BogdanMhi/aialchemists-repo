import re
import json
import base64
from utilities.settings import (
     VIDEO_HANDLER_TRIGGER,
     TEXT_PROCESSOR_TRIGGER,
     IOT_HANDLER_TRIGGER,
     DOCUMENT_HANDLER_TRIGGER,
     IMAGE_HANDLER_TRIGGER,
     INGESTION_DATA_BUCKET
)
from utilities.publisher import publish_message
from google.cloud import storage


video_file_extensions = [
    "wav", 
    "mp3", 
    "mp4", 
    "mpweg", 
    "mpga", 
    "m4a", 
    "webm"
]

image_file_extensions = [
    ".jpg", ".jpeg",
    ".png",
    ".gif",
    ".bmp",
    ".tiff", ".tif",
    ".raw",
    ".svg",
    ".webp"
]

document_file_extensions = [
    ".doc", ".docx",
    ".xls", ".xlsx",
    ".ppt", ".pptx",
    ".pdf",
    ".txt",
    ".rtf",
    ".csv",
    ".odt", ".ods", ".odp",  # OpenDocument formats
    ".pages", ".numbers", ".key"  # Apple iWork formats
]

storage_client = storage.Client()
placeholder_bucket = storage_client.get_bucket(INGESTION_DATA_BUCKET)

def detect_file_type(filename):
    # Extract the file extension from the filename
    file_extension = filename.split(".")[-1]
    
    # Classify the document based on the file extension
    if file_extension.lower() in image_file_extensions:
        return IMAGE_HANDLER_TRIGGER
    elif file_extension.lower() in video_file_extensions:
        return VIDEO_HANDLER_TRIGGER
    elif file_extension.lower() in document_file_extensions:
        return DOCUMENT_HANDLER_TRIGGER
    else:
        return "unknown"

def detect_text_type(text):
    # Regular expressions to match plain text, video links, and web page links
    plain_text_pattern = re.compile(r"^[a-zA-Z0-9\s\.,!?]*$")
    video_link_pattern = re.compile(r"https?:\/\/(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)\S+")
    webpage_link_pattern = re.compile(r"(http|https)://[^\s]+")
    # Check if it's plain text
    url_links = []
    # Check if it's a video link
    if video_link_pattern.match(text):
        matches = video_link_pattern.findall(text)
        for full_link in matches:
            print("Full YouTube link:", full_link)
            url_links.append(full_link)
        return (VIDEO_HANDLER_TRIGGER, url_links)
    
    # Check if it's a web page link
    elif webpage_link_pattern.match(text):
        matches = webpage_link_pattern.findall(text)
        for full_link in matches:
            print("Web page link:", full_link)
            url_links.append(full_link)
        return (IOT_HANDLER_TRIGGER, url_links)
    
    elif plain_text_pattern.match(text):
        return (TEXT_PROCESSOR_TRIGGER, url_links)
    
    # If none of the above patterns match, return "Unknown"
    else:
        return (TEXT_PROCESSOR_TRIGGER, url_links)

def format_classifier(event, context):
    """Triggered from a message on a Cloud Pub/Sub topic.
    Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.
    """
    pubsub_message = base64.b64decode(event["data"]).decode("utf-8")
    pubsub_message_json = json.loads(pubsub_message)
    statement = pubsub_message_json["statement"]
    file_path = pubsub_message_json.get("file_path", "")
    if file_path:
        blob = placeholder_bucket.get_blob(file_path)
        trigger_option = detect_file_type(blob.name)
        if trigger_option != "unknown":
            print(f"Trigger {trigger_option} with the pub/sub message: {pubsub_message}")
            publish_message(trigger_option, pubsub_message)
            return True
        else:
            print("Unknown type document...")
            pubsub_message_json["file_path"] = "unknown"
            publish_message(TEXT_PROCESSOR_TRIGGER, json.dumps(pubsub_message_json))
            return True

    else:
        trigger_option, url_links = detect_text_type(statement)
        if url_links:
            pubsub_message_json["url_links"] = url_links
            publish_message = json.dumps(pubsub_message_json)
    print(f"{statement} has been classified as {trigger_option}")
    publish_message(trigger_option, pubsub_message)
    return True