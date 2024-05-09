import os
import json
import base64
import re
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

def remove_urls(text):
    url_pattern = re.compile(r'(https?://\S+|www\.\S+)')
    return url_pattern.sub('', text)

@functions_framework.cloud_event
def text_processor(cloud_event):
    """
    A cloud function that calls a LLM agent and processes the question addressed by the user alongside the files uploaded and/or links provided by the user in the UI (if any)
    Args:
        statement          (str): The question asked by the user in the UI
        attachement_output (str): Output of the file uploaded in the UI (if any)
        uuid               (str): Unique identifier of the user
    Returns:
        output_model (str): The answer of the LLM agent to the question addressed by the user in the UI
    """
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8')
    pubsub_message = json.loads(pubsub_message)
    statement = remove_urls(pubsub_message['statement'])
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
    
    if attachement_output:
        print("Processing question with attachment")
        template = """The following is a friendly conversation between a human and an AI.
                    The AI is a medical engine with accurate and up-to-date medical knowledge that will only answer to medical related questions.
                    The AI will always answer to greetings and the questions about previous inquiries/requests addressed by the human.
                    If the question is abstract or ambiguous, the AI will ask the human for more context.
                    The AI will use tools to look for an answer ONLY if it NEEDS to.
                    The AI's final answer will contain terms that can be understood by any human and will contain 2 sentences, plus one medical article or research that addresses the query.

                    If the question is out of context, please take a look at the full conversation you've had so far: {history}.

                    Human: Given the following information extracted from a document/video/audio/image/link: {input} I want you to answer the following request/question: {question}
                    {agent_scratchpad}"""
    else:
        print("Processing question")
        template = """The following is a friendly conversation between a human and an AI. 
                    The AI is a medical engine with accurate and up-to-date medical knowledge that will only answer to medical related questions.
                    The AI will always answer to greetings and the questions about previous inquiries/requests addressed by the human.
                    If the question is abstract or ambiguous, the AI will ask the human for more context.
                    The AI will use tools to look for an answer ONLY if it NEEDS to.
                    The AI's final answer will contain terms that can be understood by any human and will contain 2 sentences, plus one medical article or research that addresses the query.

                    If the question is out of context, please take a look at the full conversation you've had so far: {history}.

                    Human: Please answer the following request/question: {question}
                    {agent_scratchpad}"""

    prompt = PromptTemplate(input_variables=["question"], template=template)
    history = extract_all_documents_from_collection(PROJECT_ID, FIRESTORE_DATABASE_ID, uuid)
    history_merged = []
    for i in range(0, len(history), 2):
        if i+1 < len(history):
            new_dict = {**history[i],**history[i+1]}
            history_merged.append(new_dict)
    agent = create_tool_calling_agent(llm, tools, prompt)
    agent_executor = AgentExecutor(agent=agent, tools=tools, verbose=True)
    
    result = agent_executor.invoke({"question": statement, "input": attachement_output, "history": history_merged})
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