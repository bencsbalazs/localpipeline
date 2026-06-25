# AWS Workflow

This document outlines how to adapt and run the pipeline on Amazon Web Services (AWS). It focuses on leveraging AWS-managed services for scalability and reliability.

## Prerequisites

- AWS CLI configured with appropriate permissions.
- `kubectl`
- An AWS account.

## Architecture on AWS

- **Code Repository:** AWS CodeCommit or a self-hosted GitLab on EC2.
- **CI/CD Pipeline:** AWS CodePipeline or GitLab CI/CD.
- **Container Registry:** Amazon Elastic Container Registry (ECR).
- **Kubernetes Cluster:** Amazon Elastic Kubernetes Service (EKS).
- **Message Queue:** Amazon Managed Streaming for Apache Kafka (MSK).
- **Logging Database:** Amazon OpenSearch Service (successor to Elasticsearch Service).
- **Log Viewer:** OpenSearch Dashboards (included with Amazon OpenSearch Service).
- **LLM:** A custom model deployed on Amazon SageMaker.

## Setup and Migration Steps

1.  **Containerize the Application:** The existing `Dockerfile` can be used to build the application image.

2.  **Set up ECR:**
    -   Create an ECR repository to store your Docker images.
    -   Modify the `pipeline.sh` (or your CI/CD pipeline) to build the Docker image, tag it, and push it to ECR.

3.  **Set up EKS:**
    -   Create an EKS cluster.
    -   Configure `kubectl` to connect to your EKS cluster.
    -   Update the Kubernetes manifests in `k8s/`:
        -   Change `image` fields to point to your ECR repository.
        -   Replace `NodePort` services with `LoadBalancer` services for external access.
        -   Update resource requests and limits based on your expected load.
        -   For persistent data (Ollama models, Elasticsearch data), replace `emptyDir` volumes with `PersistentVolumeClaim`s backed by Amazon EBS or EFS.

4.  **Set up MSK:**
    -   Create an Amazon MSK cluster.
    -   Update the `KAFKA_BROKER` environment variable in `app.py` and `k8s/logstash.yml` to point to your MSK broker endpoints.

5.  **Set up Amazon OpenSearch:**
    -   Create an Amazon OpenSearch Service domain.
    -   Update the Elasticsearch host in `k8s/logstash.yml` to point to your OpenSearch endpoint.
    -   Kibana (OpenSearch Dashboards) will be available through the OpenSearch console.

6.  **Deploy the LLM on SageMaker:**
    -   Package the `qwen2.5-coder:1.5b` model for SageMaker.
    -   Create a SageMaker endpoint to serve the model.
    -   Modify the `handle_failure_with_ai` function in `pipeline.sh` to invoke the SageMaker endpoint instead of the local Ollama service.

7.  **CI/CD Pipeline:**
    -   Choose a CI/CD service (e.g., AWS CodePipeline, Jenkins, or GitLab CI/CD).
    -   Create a pipeline that automates the following steps:
        -   Linting, testing, and security scans (as in `pipeline.sh`).
        -   Building and pushing the Docker image to ECR.
        -   Deploying the updated Kubernetes manifests to your EKS cluster.

## Example `pipeline.sh` modifications for AWS

-   **Docker Build and Push:**
    ```bash
    aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
    docker build -t <aws_account_id>.dkr.ecr.<region>.amazonaws.com/local-app:latest .
    docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/local-app:latest
    ```

-   **Kubernetes Deployment:**
    ```bash
    kubectl apply -f k8s/ # Assuming manifests are updated for AWS
    ```
