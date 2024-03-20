# Devops Tools

Welcome to our Docker repository designed to streamline DevOps workflows. 
This Docker image contains essential tools for devops.

## Key Features:

- **Pre-installed Git:** Git is already configured in this image, making it easy to manage version control of your projects directly from your Docker environment.

- **Included Kubectl:** Kubectl is readily available in this image, enabling you to efficiently manage and interact with your Kubernetes clusters.

- **Included Trivy:** Trivy is the most popular open source security scanner, reliable, fast, and easy to use.

- **Ready for DevOps:** With all essential tools already included, you can quickly set up a complete DevOps environment to develop, test, and deploy your applications.

## How to Use:

1. **Pull the Docker Image:**
```
docker pull jansouza/devops-tools:latest
```

2. **Run a Container:**
```
docker run -it jansouza/devops-tools:latest /bin/sh
```

3. **Interact with Kubectl:**
```
kubectl get pods
kubectl apply -f your-config-file.yaml
```

4. **Interact with Trivy:**
```
trivy image python:3.4-alpine
trivy k8s --report summary --timeout 3600s cluster
```

5. **Utilize Git:**
```
git clone your-git-repository
git commit -m "Your commit"
git push origin main
```

## Contribution:

This repository is maintained by our team, but we encourage contributions from the community for improvements and fixes. Feel free to submit pull requests and report issues to help make this repository even more useful for everyone.


## Feedback:

We value your feedback! If you have any suggestions, questions, or issues, please don't hesitate to open an issue or reach out to us directly.
Thank you for choosing our Docker repository to simplify your DevOps workflows. We hope this image proves valuable for your projects.