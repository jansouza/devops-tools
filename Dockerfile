FROM alpine:latest as base
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "TARGETPLATFORM=$TARGETPLATFORM BUILDPLATFORM=$BUILDPLATFORM"

# Install pakages
RUN apk add --no-cache \
    ca-certificates \
    bash \
    curl \
    git


# kubectl
FROM base as kubectl
RUN KUBECTL_VERSION=$(curl -sSL https://dl.k8s.io/release/stable.txt); \
    if [[ "$TARGETPLATFORM" == *"arm"* ]]; then \
        curl -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/arm64/kubectl; \
        chmod +x /usr/local/bin/kubectl; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        curl -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl; \
        chmod +x /usr/local/bin/kubectl; \
    else \
        echo "Not supported"; \
        exit 1; \
    fi
RUN mkdir -p ~/.kube