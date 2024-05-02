import json
import base64
import functions_framework
import tika

from google.cloud import storage
from utilities.publisher import publish_message
from utilities.settings import TEXT_PROCESSOR_TRIGGER


tika.initVM()
from tika import parser


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

# Triggered from a message on a Cloud Pub/Sub topic.
client_storage = storage.Client()

@functions_framework.cloud_event
def document_handler(cloud_event):
    """
    A cloud function that extracts the content of a document

    Args:
        cloud_event (str): The path to the doc file to be checked
    Returns:
        output_text (str): extracted text from the provided document
    """
    
    # if link then parse
    # if file path then use bucket location to parse

    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
    pubsub_message_json = json.loads(pubsub_message)
    file_name = pubsub_message_json["file_path"]

    if ('http' or 'www') in file_name:
      output_text = extract_text_from_doc(file_name)
    else:
      doc_bucket = client_storage.get_bucket("ingestion_data_bucket")
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
