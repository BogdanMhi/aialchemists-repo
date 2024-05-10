"""
A module to abstract away interactions with pub/sub
"""

from concurrent import futures
from google.cloud import pubsub_v1
from typing import Callable
from .settings import PROJECT_ID


def publish_message(topic_id: str, data: str, attributes: dict = None) -> None:
    """Publish a message to a Google Cloud Pub/Sub topic.

    Args:
        topic_id (str): The ID of the topic to publish to.
        data (str): The message to be published.
        attributes (dict): The attributes to use.

    Returns:
        None

    Raises:
        TimeoutError: If the publishing call times out after 60 seconds.
    """
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project=PROJECT_ID, topic=topic_id)
    publish_futures = []

    def get_callback(
        publish_future: pubsub_v1.publisher.futures.Future, data: str
    ) -> Callable[[pubsub_v1.publisher.futures.Future], None]:
        def callback(publish_future: pubsub_v1.publisher.futures.Future) -> None:
            try:
                # Wait 60 seconds for the publish call to succeed.
                print(f"Message ID: {publish_future.result(timeout=60)}")
            except futures.TimeoutError:
                print(f"Publishing {data} timed out.")

        return callback

    # When you publish a message, the client returns a future.
    publish_future = publisher.publish(
        topic=topic_path, data=data.encode("utf-8"), **(attributes or {})
    )
    # Non-blocking. Publish failures are handled in the callback function.
    publish_future.add_done_callback(get_callback(publish_future, data))
    publish_futures.append(publish_future)

    # Wait for all the publish futures to resolve before exiting.
    futures.wait(publish_futures, return_when=futures.ALL_COMPLETED)
    print(f"Published message to {topic_path}.")