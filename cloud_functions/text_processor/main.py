import os
import json
import base64
import functions_framework
import requests

from google.cloud import bigquery
from langchain.agents import initialize_agent, Tool, AgentType
from langchain_openai import AzureChatOpenAI
from langchain_community.tools.pubmed.tool import PubmedQueryRun
from utilities.settings import *

bigquery_client = bigquery.Client()

llm = AzureChatOpenAI(deployment_name="gpt-4", model_name="gpt-4",
                    api_key = AZURE_OPENAI_API_KEY,  
                    api_version = "2024-02-01",
                    azure_endpoint = AZURE_OPENAI_ENDPOINT,
                    temperature = 0)

pub_med = PubmedQueryRun()
tools = [
    Tool(
        name = "query_pub_med",
        func=pub_med.invoke,
        description="useful for when you need to answer questions about medical topics"
    )
]

PREFIX = """Analyze the given input and tell me if the information is supported by any medical research. You also have access to the following medical tools:"""
FORMAT_INSTRUCTIONS = """Use the following format:

Question: the input question you must answer
Thought: you should always think about what to do
Action: the action to take, should first search in your memory and if you don't have an answer, you should query one of these tools [{tool_names}]
Action Input: the input to the action
Observation: the result of the action
... (this Thought/Action/Action Input/Observation can repeat N times)
Thought: I now know the final answer
Final Answer: format the final answer to the original input question and also specify the title, authors and web links to the articles you used as inspiration"""
SUFFIX = """Begin!

Input: {input}
Thought:{agent_scratchpad}"""

agent = initialize_agent(
    agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
    tools=tools,
    llm=llm,
    agent_kwargs={
        'prefix':PREFIX,
        'format_instructions':FORMAT_INSTRUCTIONS,
        'suffix':SUFFIX
    },
    verbose=True,
    handle_parsing_errors=True
)


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
    print(pubsub_message)
    # Query the BigQuery table to check if the uuid exists
    try:
        query = f"""
            SELECT uuid
            FROM `docai-accelerator.aialchemists_user_table.users`
            WHERE uuid = '{uuid}'
        """
        query_job = bigquery_client.query(query)
        results = list(query_job)
        if not results:
            print(f"UUID '{uuid}' not found in the user table.")
            return 'UUID not found', 404
    except Exception as e:
        print('Error querying BigQuery table:', e)
        return 'Error querying BigQuery table', 500
    ip = requests.get('https://api.ipify.org').text
    print(f'My public IP address is: {ip}')


    result = agent.invoke(statement)
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