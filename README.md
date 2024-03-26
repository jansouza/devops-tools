# Devops Tools

Welcome to our Docker repository designed to streamline DevOps workflows. 
This Docker image contains essential tools for devops.

## Key Features:

- **Pre-installed Git:** Git is already configured in this image, making it easy to manage version control of your projects directly from your Docker environment.

- **Included Kubectl:** Kubectl is readily available in this image, enabling you to efficiently manage and interact with your Kubernetes clusters.

- **Included Sonar Scanner:** The SonarScanner CLI is the scanner to use when there is no specific scanner for your build system.

- **Included Trivy:** Trivy is the most popular open source security scanner, reliable, fast, and easy to use.

- **Included Gitleaks:** Gitleaks is a SAST tool for detecting and preventing hardcoded secrets like passwords, api keys, and tokens in git repos. Gitleaks is an easy-to-use, all-in-one solution for detecting secrets, past or present, in your code.

- **Included Skopeo:** Skopeo is a tool for manipulating, inspecting, signing, and transferring container images and image repositories on Linux® systems, Windows and MacOS. Like Podman and Buildah, Skopeo is an open source community-driven project that does not require running a container daemon..

- **Ready for DevOps:** With all essential tools already included, you can quickly set up a complete DevOps environment to develop, test, and deploy your applications.

## How to Use:

1. **Pull the Docker Image:**
    ```
    docker pull jansouza/devops-tools:latest
    ```

2. **Run a Container:**
    ```
    docker run -it jansouza/devops-tools:latest /bin/sh

    docker exec -it <container-name-or-id> bash
    ```

3. **Utilize Git:**
    ```
    git clone your-git-repository
    git commit -m "Your commit"
    git push origin main
    ```

4. **Interact with Kubectl:**
    ```
    kubectl get pods
    kubectl apply -f your-config-file.yaml
    ```

5. **Interact with Trivy:**
    ```
    trivy image python:3.4-alpine
    trivy k8s --report summary --timeout 3600s cluster
    ```

6. **Interact with Sonar Scanner:**
    ```
    export SONAR_TOKEN=*****************
    sonar-scanner -Dsonar.projectKey=lab-app -Dsonar.sources=src/ -Dsonar.host.url=http://0.0.0.0:9000
    ```

7. **Interact with Gitleaks:**
    ```
    gitleaks detect --source . -v
    ```

8. **Interact with skopeo:**
    ```
    skopeo copy docker://jjasghar/catapp:latest docker://quay.io/jjasghar/catapp:latest
    ```


## Contribution:

This repository is maintained by our team, but we encourage contributions from the community for improvements and fixes. Feel free to submit pull requests and report issues to help make this repository even more useful for everyone.


## Feedback:

We value your feedback! If you have any suggestions, questions, or issues, please don't hesitate to open an issue or reach out to us directly.
Thank you for choosing our Docker repository to simplify your DevOps workflows. We hope this image proves valuable for your projects.