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

# Consistent use of file extensions (without dots for all)
video_file_extensions = [
    "wav", 
    "mp3", 
    "mp4", 
    "mpeg",  # corrected typo
    "mpga", 
    "m4a", 
    "webm"
]

image_file_extensions = [
    "jpg", "jpeg",
    "png",
    "gif",
    "bmp",
    "tiff", "tif",
    "raw",
    "svg",
    "webp"
]

document_file_extensions = [
    "doc", "docx",
    "xls", "xlsx",
    "ppt", "pptx",
    "pdf",
    "txt",
    "rtf",
    "csv",
    "odt", "ods", "odp",
    "pages", "numbers", "key"
]

storage_client = storage.Client()
placeholder_bucket = storage_client.get_bucket(INGESTION_DATA_BUCKET)

def detect_file_type(filename):
    file_extension = filename.split(".")[-1].lower()
    if file_extension in image_file_extensions:
        return IMAGE_HANDLER_TRIGGER
    elif file_extension in video_file_extensions:
        return VIDEO_HANDLER_TRIGGER
    elif file_extension in document_file_extensions:
        return DOCUMENT_HANDLER_TRIGGER
    else:
        return "unknown"

def detect_text_type(text):
    video_link_pattern = re.compile(r"https?:\/\/(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)\S+")
    webpage_link_pattern = re.compile(r"https?:\/\/[^\s]+")
    plain_text_pattern = re.compile(r"^[\w\s\.,!?()\"'-]+$")

    url_links = []
    video_match = video_link_pattern.search(text)
    webpage_match = webpage_link_pattern.search(text)
    
    if video_match:
        for match in video_link_pattern.findall(text):
            url_links.append(match)
        return (VIDEO_HANDLER_TRIGGER, url_links)
    elif webpage_match:
        for match in webpage_link_pattern.findall(text):
            url_links.append(match)
        return (IOT_HANDLER_TRIGGER, url_links)
    elif plain_text_pattern.match(text):
        return (TEXT_PROCESSOR_TRIGGER, url_links)
    else:
        return (TEXT_PROCESSOR_TRIGGER, url_links)

def format_classifier(event, context):
    try:
        pubsub_message = base64.b64decode(event["data"]).decode("utf-8")
        pubsub_message_json = json.loads(pubsub_message)
    except Exception as e:
        print(f"Error decoding or parsing message: {e}")
        return False

    statement = pubsub_message_json["statement"]
    file_path = pubsub_message_json.get("file_path", "")
    
    if file_path:
        try:
            blob = placeholder_bucket.get_blob(file_path)
            if blob:
                trigger_option = detect_file_type(blob.name)
                if trigger_option != "unknown":
                    print(f"Trigger {trigger_option} with the pub/sub message: {pubsub_message}")
                    publish_message(trigger_option, pubsub_message)
                else:
                    print("Unknown type document...")
                    pubsub_message_json["file_path"] = "unknown"
                    publish_message(TEXT_PROCESSOR_TRIGGER, json.dumps(pubsub_message_json))
            else:
                print("Blob not found.")
                return False
        except Exception as e:
            print(f"Error handling blob: {e}")
            return False
    else:
        trigger_option, url_links = detect_text_type(statement)
        if url_links:
            pubsub_message_json["url_links"] = url_links
            pubsub_message = json.dumps(pubsub_message_json)
        print(f"{statement} has been classified as {trigger_option}")
        publish_message(trigger_option, pubsub_message)

    return True