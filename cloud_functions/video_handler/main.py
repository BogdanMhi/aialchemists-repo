import whisper
import json, base64
import functions_framework
from google.cloud import storage
from pytube import YouTube
from utilities.publisher import publish_message
from utilities.settings import TEXT_PROCESSOR_TRIGGER

@functions_framework.cloud_event
def video_handler(cloud_event):
    """
    A cloud function that extracts the audio into text from a video file

    Args:
        statement (str): The question asked by the user in the UI
        url_links (str): The link to the youtube item to be processed (if any)
        file_path (str): Name of the audio/video file uploaded in the UI and needs to be processed (if any)
        uuid      (str): Unique identifier of the user
    Returns:
        transcript (str): Content of the video/audio object or youtube link
    """
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
    message_data = json.loads(pubsub_message)
    file_path = message_data.get("file_path", "")

    if file_path:
        storage_client = storage.Client()
        bucket = storage_client.get_bucket("whisper-data")
        model = whisper.load_model("small")
        blob = bucket.get_blob(file_path)
        object_path = blob.name
        blob.download_to_filename(f"/tmp/{object_path}")
    else:
        url_link = message_data['url_links'][0]
        yt_obj = YouTube(url_link)
        object_path = yt_obj.title
        filters = yt_obj.streams.filter(progressive=True, file_extension='mp4')
        filters.get_highest_resolution().download(output_path="/tmp/") 

    result = model.transcribe(f"/tmp/{object_path}", fp16=False)
    transcript = json.dumps({
        "statement": message_data["statement"],
        "attachement_output": result["text"],
        "uuid": message_data["uuid"]
        })
    print(transcript)
    publish_message(TEXT_PROCESSOR_TRIGGER, transcript)