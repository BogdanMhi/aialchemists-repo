import whisper
import json, base64
import functions_framework
from google.cloud import storage
from pytube import YouTube
from utilities.publisher import publish_message

@functions_framework.cloud_event
def video_handler(cloud_event):
    """
    A cloud function that extracts the audio into text from a video file

    Args:
        object_type (str): Type of the parsed object (youtube/video)
        object_path (str): Path where the object can be found (youtube link/name of the file to be searched in cloud storage)
    Returns:
        transcript (str): Content of the video/audio object
    """
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
    message_data = json.loads(pubsub_message)
    object_type = message_data['object_type']
    object_path = message_data['object_path']

    if object_type == 'video':
        storage_client = storage.Client()
        bucket = storage_client.get_bucket("whisper-data")
        model = whisper.load_model("small")
        blob = bucket.get_blob(object_path)
        blob.download_to_filename(f"/tmp/{object_path}")
    elif object_type == 'youtube':
        yt_obj = YouTube(object_path)
        object_path = yt_obj.title
        filters = yt_obj.streams.filter(progressive=True, file_extension='mp4')
        filters.get_highest_resolution().download(output_path="/tmp/") 

    result = model.transcribe(f"/tmp/{object_path}", fp16=False)
    
    transcript = json.dumps({"text": result["text"]})
    print(transcript)
    # publish_message(topic_name, transcript)