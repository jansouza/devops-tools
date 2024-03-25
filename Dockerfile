FROM alpine:edge AS base
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "TARGETPLATFORM=$TARGETPLATFORM BUILDPLATFORM=$BUILDPLATFORM"

# Install pakages
RUN apk add --no-cache \
    ca-certificates \
    bash \
    curl \
    git \
    jq

# Copy scripts
COPY scripts/. /usr/local/bin/.

FROM base AS tools

##########
# kubectl
##########
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


##########
# trivy
##########
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin


##########
# sonar-scanner-cli
##########

# Install pakages
RUN apk add --no-cache \
    openjdk17 \
    nodejs

WORKDIR /usr/local

# Download
ARG CLI_VERSION=5.0.1.3006
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$CLI_VERSION.zip

# Unzip
RUN unzip sonar-scanner-cli-$CLI_VERSION.zip
RUN rm -f sonar-scanner-cli-$CLI_VERSION.zip
RUN mv /usr/local/sonar-scanner-$CLI_VERSION /usr/local/sonar-scanner
RUN ln -s /usr/local/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
RUN ln -s /usr/local/sonar-scanner/bin/sonar-scanner-debug /usr/local/bin/sonar-scanner-debug

WORKDIR /