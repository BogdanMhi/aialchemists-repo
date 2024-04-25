import os
import json
import base64
import functions_framework
from google.cloud import firestore
from google.cloud import bigquery
from langchain.agents import create_tool_calling_agent, Tool, AgentExecutor
from langchain_openai import AzureChatOpenAI
from langchain.prompts import PromptTemplate
from langchain_community.tools.pubmed.tool import PubmedQueryRun
from utilities.settings import AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, PROJECT_ID, FIRESTORE_DATABASE_ID, BIGQUERY_DATABASE_ID
import requests

llm = AzureChatOpenAI(deployment_name="gpt-4", model_name="gpt-4",
                    api_key = AZURE_OPENAI_API_KEY,  
                    api_version="2024-02-01",
                    azure_endpoint = AZURE_OPENAI_ENDPOINT,
                    temperature=0)

pub_med = PubmedQueryRun()
tools = [
    Tool(
        name = "query_pub_med",
        func=pub_med.invoke,
        description="useful for when you need to answer questions about medical topics"
    )
]

def extract_all_documents_from_collection(project_id, database_id, collection_name):
    """
    Extracts all documents from a Firestore collection in a specific database.
 
    Parameters:
        project_id (str): The Google Cloud project ID.
        database_id (str): The ID of the Firestore database (e.g., "(default)" for the default database).
        collection_name (str): The name of the Firestore collection from which documents need to be extracted.
 
    Returns:
        list: A list containing all the documents extracted from the collection.
    """
    firestore_client = firestore.Client(project=project_id, database=database_id)
    collection_ref = firestore_client.collection(collection_name)
    query = collection_ref.order_by('timestamp')
    documents = [doc.to_dict() for doc in query.stream()]
 
    return documents

@functions_framework.cloud_event
def text_processor(cloud_event):
    """Triggered from a message on a Cloud Pub/Sub topic.
    Args:
         cloud_event
    """
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
    pubsub_message = json.loads(pubsub_message)
    statement = pubsub_message['statement']
    uuid = pubsub_message['uuid']
    # to be used in attachement_output
    attachement_output = pubsub_message.get('attachement_output', '')
    print(pubsub_message)
    # Query the BigQuery table to check if the uuid exists
    client = bigquery.Client()
    try:
        query = f"""
            SELECT uuid
            FROM `{BIGQUERY_DATABASE_ID}`
            WHERE uuid = '{uuid}'
        """
        query_job = client.query(query)
        results = list(query_job)
        if not results:
            print(f"UUID '{uuid}' not found in the user table.")
            return 'UUID not found', 404
    except Exception as e:
        print('Error querying BigQuery table:', e)
        return 'Error querying BigQuery table', 500

    template = """The following is a serious conversation between a human and an AI. 
    The AI is a medical engine with accurate and up-to-date medical knowledge that will only answer to medical questions.
    The AI will always answer to greetings.
    If the AI receives a non-medical question, apart from greetings, it says that the question is not related to the medical field and asks the human if he wants to adress another question.
    The AI will use tools to look for an answer ONLY if it NEEDS to.
    The AI's final answer will contain 2 sentences, plus medical articles and/or researches that addresses the query, only if it does.

    Current conversation:
    {history}

    Human: Given the following information: {input}
    I want you to tell me if the information is supported by any medical research
    {agent_scratchpad}"""

    prompt = PromptTemplate(input_variables=["input"], template=template)
    history = extract_all_documents_from_collection(PROJECT_ID, FIRESTORE_DATABASE_ID, uuid)
    agent = create_tool_calling_agent(llm, tools, prompt)
    agent_executor = AgentExecutor(agent=agent, tools=tools, verbose=True)

    result = agent_executor.invoke({"input": statement, "history": history})
    output_model = result['output']

    try:
        url = 'https://app-adwexujega-ey.a.run.app/model'
        data = {
            'response': str(output_model).replace('"',"'"),
            'uuid': uuid
        }
        response = requests.post(url, json=data)
        response_data = response.json
        print(response_data)
        return 'POST request successful', 200
    except Exception as e:
        print('Error making POST request:', e)
        return 'Error making POST request', 500