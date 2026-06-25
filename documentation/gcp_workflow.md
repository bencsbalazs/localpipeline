# GCP Workflow

This document outlines how to adapt and run the pipeline on Google Cloud Platform (GCP). It focuses on leveraging GCP-managed services for scalability and reliability.

## Prerequisites

- `gcloud` CLI configured with appropriate permissions.
- `kubectl`
- A GCP project.

## Architecture on GCP

- **Code Repository:** Google Cloud Source Repositories or a self-hosted GitLab on GCE.
- **CI/CD Pipeline:** Google Cloud Build or GitLab CI/CD.
- **Container Registry:** Google Artifact Registry (or Container Registry).
- **Kubernetes Cluster:** Google Kubernetes Engine (GKE).
- **Message Queue:** Google Cloud Pub/Sub.
- **Logging Database & Viewer:** Google Cloud Logging and Monitoring (Operations Suite).
- **LLM:** A custom model deployed on Google Cloud Vertex AI.

## Setup and Migration Steps

1.  **Containerize the Application:** The existing `Dockerfile` can be used.

2.  **Set up Artifact Registry:**
    -   Create a Docker repository in Artifact Registry.
    -   Modify the `pipeline.sh` (or your CI/CD pipeline) to build, tag, and push the Docker image to Artifact Registry.

3.  **Set up GKE:**
    -   Create a GKE cluster.
    -   Configure `kubectl` to connect to your GKE cluster.
    -   Update the Kubernetes manifests in `k8s/`:
        -   Change `image` fields to point to your Artifact Registry repository.
        -   Replace `NodePort` services with `LoadBalancer` services for external access.
        -   Update resource requests and limits.
        -   For persistent data, use `PersistentVolumeClaim`s backed by Google Persistent Disk.

4.  **Set up Pub/Sub:**
    -   Create a Pub/Sub topic (e.g., `app-logs`).
    -   Update `app.py` to use the Google Cloud Pub/Sub client library instead of `kafka-python`. This is a more significant code change.
    -   Remove the Kafka and Zookeeper deployments from `k8s/kafka.yml`.

5.  **Set up Cloud Logging:**
    -   GKE is natively integrated with Google Cloud Logging. Logs from your application's `stdout` will automatically be collected.
    -   To get logs into Cloud Logging via Pub/Sub (for a more decoupled architecture), create a Cloud Function or Dataflow job that subscribes to the Pub/Sub topic and writes to the Cloud Logging API.
    -   Remove the Elasticsearch, Kibana, and Logstash deployments from your Kubernetes manifests.

6.  **Deploy the LLM on Vertex AI:**
    -   Package the `qwen2.5-coder:1.5b` model and deploy it to a Vertex AI endpoint.
    -   Modify the `handle_failure_with_ai` function in `pipeline.sh` to make authenticated API calls to the Vertex AI endpoint.

7.  **CI/CD Pipeline with Cloud Build:**
    -   Create a `cloudbuild.yaml` file to define your CI/CD pipeline.
    -   The pipeline will perform the scan, build, push, and deploy steps.

## Example `cloudbuild.yaml` step for building and pushing

```yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repo/local-app:latest', '.']
- name: 'gcr.io/cloud-builders/docker'
  args: ['push', 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repo/local-app:latest']
```

## Example `app.py` change for Pub/Sub

```python
# from kafka import KafkaProducer
from google.cloud import pubsub_v1
import os

# producer = KafkaProducer(...)
project_id = os.getenv("GCP_PROJECT_ID")
topic_id = "app-logs"
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_id)

def log_to_pubsub(message):
    try:
        # data needs to be a bytestring
        data = json.dumps(message).encode("utf-8")
        future = publisher.publish(topic_path, data)
        print(future.result())
    except Exception as e:
        print(f"Could not send message to Pub/Sub: {e}")

# In get_fizzbuzz_result and other functions:
# log_to_kafka(...) becomes log_to_pubsub(...)
```
