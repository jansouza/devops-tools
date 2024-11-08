FROM alpine:edge AS base
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "TARGETPLATFORM=$TARGETPLATFORM BUILDPLATFORM=$BUILDPLATFORM"

# Install pakages
RUN apk add --no-cache \
    ca-certificates \
    bash \
    curl \
    curl-dev \
    git \
    jq \
    skopeo

# Copy scripts
COPY scripts/. /usr/local/bin/.

FROM base AS tools
ARG TARGETPLATFORM

############
# kubectl
############
RUN KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt); \
    if [[ "$TARGETPLATFORM" == *"arm"* ]]; then \
        curl -o /usr/local/bin/kubectl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/arm64/kubectl; \
        chmod +x /usr/local/bin/kubectl; \
    elif [[ "$TARGETPLATFORM" == "linux/amd64" || "$TARGETPLATFORM" == "x86_64" ]]; then \
        curl -o /usr/local/bin/kubectl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; \
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


####################
# sonar-scanner-cli
##########

# Install pakages
RUN apk add --no-cache \
    openjdk17 \
    nodejs

WORKDIR /usr/local

# Download
ARG CLI_VERSION=6.2.1.4610
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${CLI_VERSION}.zip

# Install
RUN unzip sonar-scanner-cli-$CLI_VERSION.zip; \
    rm -f sonar-scanner-cli-$CLI_VERSION.zip; \
    mv /usr/local/sonar-scanner-$CLI_VERSION /usr/local/sonar-scanner; \
    ln -s /usr/local/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner; \
    ln -s /usr/local/sonar-scanner/bin/sonar-scanner-debug /usr/local/bin/sonar-scanner-debug


#############
# gitleaks
#############

# Install
ARG GITLEAKS_VERSION=8.21.2
RUN if [[ "$TARGETPLATFORM" == *"arm"* ]]; then \
        wget -O /usr/local/bin/gitleaks.tar.gz https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_arm64.tar.gz; \
    elif [[ "$TARGETPLATFORM" == "linux/amd64" || "$TARGETPLATFORM" == "x86_64" ]]; then \
        wget -O /usr/local/bin/gitleaks.tar.gz https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz; \
    else \
        echo "Not supported"; \
        exit 1; \
    fi

RUN tar -xzvf /usr/local/bin/gitleaks.tar.gz -C /usr/local/bin
RUN rm -f /usr/local/bin/gitleaks.tar.gz; rm -f /usr/local/bin/LICENSE; rm -f /usr/local/bin/README.md
RUN chmod +x /usr/local/bin/gitleaks


#############
# terraform
#############

ENV TERRAFORM_VERSION=1.9.8
ENV TFLINT_VERSION=0.53.0

# Install Terraform
RUN if [[ "$TARGETPLATFORM" == *"arm"* ]]; then \
        wget -O /usr/local/bin/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_arm64.zip; \
    elif [[ "$TARGETPLATFORM" == "linux/amd64" || "$TARGETPLATFORM" == "x86_64" ]]; then \
        wget -O /usr/local/bin/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip; \
    else \
        echo "Not supported"; \
        exit 1; \
    fi

RUN unzip /usr/local/bin/terraform.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/terraform \
    && rm /usr/local/bin/terraform.zip

# Install TFLint
RUN if [[ "$TARGETPLATFORM" == *"arm"* ]]; then \
        wget -O /usr/local/bin/tflint.zip https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_arm64.zip; \
    elif [[ "$TARGETPLATFORM" == "linux/amd64" || "$TARGETPLATFORM" == "x86_64" ]]; then \
        wget -O /usr/local/bin/tflint.zip https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip; \
    else \
        echo "Not supported"; \
        exit 1; \
    fi

RUN unzip /usr/local/bin/tflint.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/tflint \
    && rm /usr/local/bin/tflint.zip


#############
# AWS CLI
#############

# Install pakages
RUN apk add --no-cache \
    aws-cli

#
WORKDIR /