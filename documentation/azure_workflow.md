# Azure Workflow

This document outlines how to adapt and run the pipeline on Microsoft Azure. It focuses on leveraging Azure-managed services for scalability and reliability.

## Prerequisites

- Azure CLI (`az`) configured with appropriate permissions.
- `kubectl`
- An Azure subscription.

## Architecture on Azure

- **Code Repository:** Azure Repos or a self-hosted GitLab on a VM.
- **CI/CD Pipeline:** Azure Pipelines or GitLab CI/CD.
- **Container Registry:** Azure Container Registry (ACR).
- **Kubernetes Cluster:** Azure Kubernetes Service (AKS).
- **Message Queue:** Azure Event Hubs (with its Kafka endpoint).
- **Logging Database & Viewer:** Azure Monitor (specifically Log Analytics).
- **LLM:** A custom model deployed on Azure Machine Learning.

## Setup and Migration Steps

1.  **Containerize the Application:** The existing `Dockerfile` can be used.

2.  **Set up ACR:**
    -   Create an Azure Container Registry.
    -   Modify your CI/CD pipeline to build, tag, and push the Docker image to ACR.

3.  **Set up AKS:**
    -   Create an AKS cluster.
    -   Configure `kubectl` to connect to your AKS cluster.
    -   Update the Kubernetes manifests in `k8s/`:
        -   Change `image` fields to point to your ACR repository.
        -   Replace `NodePort` services with `LoadBalancer` services.
        -   Update resource requests and limits.
        -   For persistent data, use `PersistentVolumeClaim`s backed by Azure Disk or Azure Files.

4.  **Set up Event Hubs:**
    -   Create an Event Hubs namespace and an Event Hub.
    -   Event Hubs provides a Kafka-compatible endpoint. Enable it.
    -   Update the `KAFKA_BROKER` environment variable in `app.py` and the Kafka broker configuration in `k8s/logstash.yml` to point to your Event Hubs Kafka endpoint. You will also need to configure SASL authentication.
    -   Remove the Kafka and Zookeeper deployments from `k8s/kafka.yml`.

5.  **Set up Azure Monitor:**
    -   AKS is natively integrated with Azure Monitor for containers. Logs from your application's `stdout` will be collected automatically.
    -   To send logs from Event Hubs to Azure Monitor, you can use an Azure Function with an Event Hubs trigger that forwards messages to a Log Analytics workspace.
    -   Remove the Elasticsearch, Kibana, and Logstash deployments.

6.  **Deploy the LLM on Azure Machine Learning:**
    -   Package the `qwen2.5-coder:1.5b` model and deploy it as a managed endpoint in Azure Machine Learning.
    -   Modify the `handle_failure_with_ai` function in `pipeline.sh` to make authenticated API calls to the Azure ML endpoint.

7.  **CI/CD Pipeline with Azure Pipelines:**
    -   Create an `azure-pipelines.yml` file to define your pipeline.
    -   The pipeline will perform the scan, build, push, and deploy steps.

## Example `azure-pipelines.yml` step for building and pushing

```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: Docker@2
  inputs:
    containerRegistry: 'your-acr-service-connection'
    repository: 'local-app'
    command: 'buildAndPush'
    Dockerfile: '**/Dockerfile'
    tags: |
      $(Build.BuildId)
      latest
```

## Example `app.py` change for Event Hubs Kafka authentication

```python
# The kafka-python library needs to support SASL_SSL
producer = KafkaProducer(
    bootstrap_servers="your-eventhubs-namespace.servicebus.windows.net:9093",
    security_protocol="SASL_SSL",
    sasl_mechanism="PLAIN",
    sasl_plain_username="$ConnectionString",
    sasl_plain_password="your-event-hubs-connection-string",
    # ... other options
)
```
