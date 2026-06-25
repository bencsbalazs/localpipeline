# Local Workflow

This document outlines how to set up and run the local pipeline on your development machine.

## Prerequisites

- Docker
- `kubectl`
- `kind`
- `snyk`
- `trivy`
- `gitleaks`

The `install_dependencies.sh` script will install `kind`, `kubectl`, `snyk`, `trivy`, and `gitleaks`. You need to install Docker manually.

## Setup

1.  **Install Dependencies:**
    ```bash
    ./install_dependencies.sh
    ```

2.  **Set up GitLab:**
    ```bash
    ./setup_gitlab.sh
    ```
    This will create a local GitLab instance in a separate Kind cluster. You will be provided with the URL and instructions to get the root password.

3.  **Configure GitLab Token:**
    -   Log in to your local GitLab instance.
    -   Create a new project.
    -   Create a Personal Access Token with `api` and `read_repository` and `write_repository` scopes.
    -   Export the token and project ID as environment variables:
        ```bash
        export GITLAB_TOKEN="your-token"
        export GITLAB_PROJECT_ID="your-project-id"
        ```

4. **(Optional) Set up SonarQube:**
    - Run a local SonarQube instance using Docker:
      ```bash
      docker run -d --name sonarqube -p 9000:9000 sonarqube:latest
      ```
    - Generate a SonarQube token and export it:
      ```bash
      export SONAR_TOKEN="your-sonarqube-token"
      ```

## Running the Pipeline

To run the entire pipeline, execute the `pipeline.sh` script:

```bash
./pipeline.sh
```

This will:
1.  Set up a Python virtual environment.
2.  Run linting, unit tests, Sonar scan, dependency scan, and secret scan.
3.  Build a Docker image of the application.
4.  Scan the Docker image for vulnerabilities.
5.  Create a new Kind cluster (`local-pipeline-cluster`).
6.  Deploy the application, Ollama, Kafka, Elasticsearch, Kibana, and Logstash to the cluster.
7.  Run a health check on the deployed application.

## Accessing Services

- **Application:** `http://localhost:8080` (after `pipeline.sh` completes and port-forwarding is active)
- **GitLab:** `http://localhost:30080`
- **SonarQube:** `http://localhost:9000`
- **Kibana:** `http://localhost:30061`
