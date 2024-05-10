import base64, json
import requests
from bs4 import BeautifulSoup
import functions_framework
from utilities.publisher import publish_message
from utilities.settings import TEXT_PROCESSOR_TRIGGER

@functions_framework.cloud_event
def IoT_handler(cloud_event):
    """
    A cloud function that extracts the content of a web page
    It is triggered by a pub/sub event and extracts the content of a web page specified in the event data.
    It retrieves the URL from the event data, makes a request to the web page, parses the HTML content, and
    returns the extracted text.
    
    Args:
        statement (str): The question asked by the user in the UI
        url_links (str): The link to the web item to be processed
        uuid      (str): Unique identifier of the user
    
    Returns:
        transcript (str): JSON-formatted string containing the statement, attachement_output (web page content) and uuid.
    """

    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
    message_data = json.loads(pubsub_message)
    item_link = message_data["url_links"][0]
    print(f"Parsing web link: {item_link}")
    res = requests.get(item_link)
    html_doc = res.content
    soup = BeautifulSoup(html_doc, 'html.parser')
    transcript = json.dumps({
        "statement": message_data["statement"],
        "attachement_output": soup.get_text().strip(),
        "uuid": message_data["uuid"]
        })
    print(transcript)
    publish_message(TEXT_PROCESSOR_TRIGGER, transcript)