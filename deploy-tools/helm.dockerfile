FROM alpine as base

# Step 1: Build basic tools in a temporary image
FROM base as builder

# Installing dependencies
RUN apk add --no-cache curl ca-certificates bash openssl

# Install kubectl
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /tmp/kubectl

# Installing the helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    mv /usr/local/bin/helm /tmp/helm

# Step 2: Creating the final image
FROM base as runner

# Dependency installation
RUN apk add --no-cache curl jq

# Copy tools from a temporary image
COPY --from=builder /tmp/kubectl /usr/local/bin/kubectl
COPY --from=builder /tmp/helm /usr/local/bin/helm
