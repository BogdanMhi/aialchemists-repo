import whisper
import json, base64
from flask import Flask, request
from google.cloud import storage
from google.cloud import bigquery
from pytube import YouTube
from utilities.publisher import publish_message
from utilities.settings import *

app = Flask(__name__)
storage_client = storage.Client(project=PROJECT_ID)
bq_client = bigquery.Client(project=PROJECT_ID)
bucket = storage_client.get_bucket(INGESTION_DATA_BUCKET)

def check_events_duplicates(event_id):
    """
    Checks if an event ID already exists in the BigQuery table meaning it was already processed.
    If the event has been processed, the function returns True.
    If the event has not been processed, the function inserts the new event ID into the idempotency table and returns False.

    Args:
        event_id (str): The event ID to check.

    Returns:
        bool: True if the event ID exists, False otherwise.
    """
    table_id = f"{PROJECT_ID}.idempotency.video_handler_msg_ids"
    query = f"SELECT count(message_id) total_rows FROM `{table_id}` WHERE message_id = '{event_id}'"
    results = bq_client.query(query)
    for row in results:
        if row[0]>0:
            return True
        else:
            bq_client.query(f"INSERT INTO `{table_id}` VALUES ('{event_id}')")
            return False
        
def video_handler(pubsub_message):
    """
    A cloud function that extracts audio into text from a video file or a YouTube link.

    Args:
        statement (str): The question asked by the user in the UI
        url_links (str): The link to the youtube item to be processed (if any)
        file_path (str): Name of the audio/video file uploaded in the UI and needs to be processed (if any)
        uuid      (str): Unique identifier of the user
    
    Returns:
        transcript (str): JSON-formatted string containing the statement, attachement_output (content of the video/audio file or YouTube link) and uuid.
    """

    message_data = json.loads(pubsub_message)
    file_path = message_data.get("file_path", "")

    if file_path:
        blob = bucket.get_blob(file_path)
        object_path = blob.name
        blob.download_to_filename(f"/tmp/{object_path}")
    else:
        url_link = message_data['url_links'][0]
        yt_obj = YouTube(url_link)
        # object_path = f"{yt_obj.title}.mp4"
        object_path = 'video.mp4'
        filters = yt_obj.streams.filter(progressive=True, file_extension='mp4')
        filters.get_highest_resolution().download(output_path="/tmp/", filename='video.mp4')
    model = whisper.load_model("small", download_root="./model/whisper/")
    result = model.transcribe(f"/tmp/{object_path}", fp16=False)
    transcript = json.dumps({
        "statement": message_data["statement"],
        "attachement_output": result["text"],
        "uuid": message_data["uuid"]
        })
    print(transcript)
    publish_message(TEXT_PROCESSOR_TRIGGER, transcript)


@app.route("/", methods=["POST"])
def index():
    """
    Receive and parse Pub/Sub messages.
    
    This function receives Pub/Sub messages, checks for their validity,
    and processes them if they contain audio/video files or YouTube links.
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
            video_handler(message)

    return ("", 200)

if __name__ == '__main__':
    app.run()