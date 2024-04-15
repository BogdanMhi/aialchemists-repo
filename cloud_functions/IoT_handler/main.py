import base64, json
import requests
from bs4 import BeautifulSoup
import functions_framework
from langchain_community.document_loaders import YoutubeLoader

@functions_framework.cloud_event
def main(cloud_event):
    """
    A cloud function that extracts the content of a web page or the transcript of a youtube object

    Args:
        item_type (str): The type of the processed item (youtube/web)
        item_link (str): The link to the item to be processed
    Returns:
        transcript (str): Content of the web page/youtube object
    """
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
    message_data = json.loads(pubsub_message)
    item_type = message_data['item_type']
    item_link = message_data['item_link']

    if item_type.lower() == 'youtube':
        print("Parsing youtube link")
        loader = YoutubeLoader.from_youtube_url(item_link, add_video_info=False, translation="en")
        page = loader.load()
        transcript = json.dumps({"text": page[0].page_content})
        print(transcript)
    elif item_type.lower() == 'web':
        print("Parsing web link")
        res = requests.get(item_link)
        html_doc = res.content
        soup = BeautifulSoup(html_doc, 'html.parser')
        transcript = json.dumps({"text": soup.get_text().strip()})
        print(transcript)