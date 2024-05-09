import json
import base64
import tika
from flask import Flask, request
from google.cloud import storage
from google.cloud import bigquery
from utilities.publisher import publish_message
from utilities.settings import *
from tika import parser

tika.initVM()
app = Flask(__name__)

client_storage = storage.Client()
bq_client = bigquery.Client(project=PROJECT_ID)

def check_events_duplicates(event_id):
    table_id = f"{PROJECT_ID}.idempotency.document_handler_msg_ids"
    query = f"SELECT count(message_id) total_rows FROM `{table_id}` WHERE message_id = '{event_id}'"
    results = bq_client.query(query)
    for row in results:
        if row[0]>0:
            return True
        else:
            bq_client.query(f"INSERT INTO `{table_id}` VALUES ('{event_id}')")
            return False
        
def extract_text_from_doc(file_path):
    """
      Function to extract text from any file. 
      Available extensions are: txt, pdf, doc/x, xls/x, csv, ppt/x

      Args:
          file_path (str): The path to the doc file to be checked.
      Returns:
          text (str): extracted text from document provided
    """
    parsed_document = parser.from_file(file_path)
    text = parsed_document["content"]

    return text

def document_handler(pubsub_message):
    """
    A cloud function that extracts the content of a document

    Args:
        cloud_event (str): The path to the doc file to be checked
    Returns:
        output_text (str): extracted text from the provided document
    """
    
    # if link then parse
    # if file path then use bucket location to parse

    pubsub_message_json = json.loads(pubsub_message)
    file_name = pubsub_message_json["file_path"]

    if ('http' or 'www') in file_name:
        output_text = extract_text_from_doc(file_name)
    else:
        doc_bucket = client_storage.get_bucket(INGESTION_DATA_BUCKET)
        doc_blob = doc_bucket.get_blob(file_name)
        file_path = f"/tmp/{file_name.split('/')[-1]}"
        doc_blob.download_to_filename(file_path)      
        output_text = extract_text_from_doc(file_path)

    print(output_text)
    output_message = json.dumps({
      "statement": pubsub_message_json["statement"],
      "attachement_output": output_text,
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
        context = pubsub_message["message_id"]
        if not check_events_duplicates(context):
            document_handler(message)

    return ("", 200)

if __name__ == '__main__':
    app.run()