import base64, json
import requests
from bs4 import BeautifulSoup
import functions_framework
from utilities.publisher import publish_message

@functions_framework.cloud_event
def IoT_handler(cloud_event):
    """
    A cloud function that extracts the content of a web page

    Args:
        item_link (str): The link to the item to be processed
    Returns:
        transcript (str): Content of the web page
    """
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
    message_data = json.loads(pubsub_message)
    item_link = message_data['item_link']

    print("Parsing web link")
    res = requests.get(item_link)
    html_doc = res.content
    soup = BeautifulSoup(html_doc, 'html.parser')
    transcript = json.dumps({"text": soup.get_text().strip()})
    print(transcript)
    # publish_message(topic_name, transcript)
