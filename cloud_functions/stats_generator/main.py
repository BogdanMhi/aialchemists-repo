import os
import base64
import json
import requests
import pytz
from google.cloud import firestore
from datetime import datetime
from google.cloud import bigquery
from langchain_openai import AzureChatOpenAI
from langchain.prompts import PromptTemplate
from langchain.chains import ConversationChain
from utilities.settings import PROJECT_ID, FIRESTORE_DATABASE_ID, AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, HISTORY_COLLECTION, BIGQUERY_DATABASE_ID

bq_client = bigquery.Client(project=PROJECT_ID)
llm = AzureChatOpenAI(deployment_name="gpt-4", model_name="gpt-4",
                    api_key=AZURE_OPENAI_API_KEY,  
                    api_version="2024-02-01",
                    azure_endpoint=AZURE_OPENAI_ENDPOINT,
                    temperature=0)


def check_firestore_documents():
    """Extracts documents from history collection. 
    The history collection contains all the conversations between all the users and the model.
    
    Returns:
        documents (list): List of documents extracted from history collection"""
    
    firestore_client = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE_ID)
    collection_ref = firestore_client.collection(HISTORY_COLLECTION)
    query = collection_ref.order_by('timestamp')
    documents = [doc.to_dict() for doc in query.stream()]

    return documents

def classify_collection(user_input):
    """Classifies documents based on the given timeframe.
    
    Args:
        user_input (str): The timeframe for classifying documents ('today', '7days', 'month', '6months', 'year') selected by the user in the UI.

    Returns:
        list: List of classified documents based on user input."""
    
    documents = check_firestore_documents()
    tz = pytz.timezone('Europe/Bucharest')
    current_time = datetime.now(tz).replace(microsecond=0).replace(tzinfo=None)

    today_collection = [doc for doc in documents if (current_time - datetime.strptime(doc['timestamp'], ("%m/%d/%Y, %H:%M:%S"))).days == 0]
    current_7days_collection = [doc for doc in documents if (current_time - datetime.strptime(doc['timestamp'], ("%m/%d/%Y, %H:%M:%S"))).days <= 7]
    current_month_collection = [doc for doc in documents if (current_time - datetime.strptime(doc['timestamp'], ("%m/%d/%Y, %H:%M:%S"))).days <= 30]
    last_6months_collection = [doc for doc in documents if (current_time - datetime.strptime(doc['timestamp'], ("%m/%d/%Y, %H:%M:%S"))).days <= 180]
    current_year_collection = [doc for doc in documents if (current_time - datetime.strptime(doc['timestamp'], ("%m/%d/%Y, %H:%M:%S"))).days <= 365]

    if user_input == 'today':
        return today_collection
    elif user_input == '7days':
        return current_7days_collection
    elif user_input == 'month':
        return current_month_collection
    elif user_input == '6months':
        return last_6months_collection
    elif user_input == 'year':
        return current_year_collection

def check_admin_users(uuid):
    """Checks if the user is an admin.
    
    Args:
        uuid (str): Unique identifier of the user

    Returns:
        bool: True if the user is an admin, False otherwise."""
    
    query = (
        f"SELECT COUNT(user_id) "
        f"FROM `{BIGQUERY_DATABASE_ID}` "
        f"WHERE uuid = '{uuid}' AND LOWER(admin) = 'true'"
    )
    query_job = bq_client.query(query)
    results = query_job.result()  # Wait for the query to complete and fetch the results
    
    return len(list(results)) > 0  # Check if any rows are returned

def stats_generator(event, context):
    """Generates statistics based on the provided timeframe.
    
    Args:
        timeframe (str): The timeframe for classifying documents ('today', '7days', 'month', '6months', 'year').
        uuid      (str): Unique identifier of the user.

    Returns:
        output_model: JSON formatted string that contains the keywords and their frequency in the conversation history of the model"""
    
    pubsub_message = base64.b64decode(event["data"]).decode("utf-8")
    pubsub_message_json = json.loads(pubsub_message)
    timeframe = pubsub_message_json['timeframe']
    uuid = pubsub_message_json['uuid']

    if not check_admin_users(uuid):
        return False
    template = """The following is a friendly conversation between a human and an AI.
        Current conversation: {history}
        Human: Given the following information: {input} please focus on the main subjects and terms that are repeated or hold significant importance in the medical context that are related to medical field and are not generic or have a common understanding apart from the medical field. 
        Return the most frequent medical keywords formatted in a list of dictionaries with two keys: keywords and frequency where the values will represent the name of the keyword and the freqency of the keyword in the input. 
        Return only the final list respecting the structure "[output]" without any additional text. All the words will be in title case.
    """
    prompt = PromptTemplate(input_variables=["input"], template=template)
    conversation = ConversationChain(prompt=prompt, llm=llm, verbose=True)
    output_model = conversation.predict(input=classify_collection(timeframe))
    print(output_model)
    print(type(output_model))
    try:
        url = 'https://web-app-adwexujega-ey.a.run.app/stats'
        data = {
            'response': output_model,
            'uuid': uuid,
        }
        headers = {'Content-Type': 'application/json'}  # Specify JSON content type
        response = requests.post(url, json=data, headers=headers)
        response_data = response.json
        print(response_data)
        return 'POST request successful', 200
    except Exception as e:
        print('Error making POST request:', e)
        return 'Error making POST request', 500
