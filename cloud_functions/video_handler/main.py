from google.cloud import storage
import whisper
import json, base64

@functions_framework.cloud_event
def main(cloud_event):
    """
    A cloud function that extracts the audio into text from a video file

    Args:
        file_name (str): Name of the file from which to extract the transcript
    Returns:
        transcript (str): Content of the video/audio object
    """
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
    message_data = json.loads(pubsub_message)
    file_name = message_data['file_name']

    storage_client = storage.Client()
    bucket = storage_client.get_bucket("whisper-data")
    model = whisper.load_model("small")
    blob = bucket.get_blob(file_name)
    blob.download_to_filename(f"/tmp/{file_name}")
    result = model.transcribe(f"/tmp/{file_name}", fp16=False)
    
    transcript = json.dumps({"text": result["text"]})
    print(transcript)
