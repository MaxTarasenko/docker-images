FROM public.ecr.aws/ubuntu/ubuntu:22.04 AS core

ARG DEBIAN_FRONTEND="noninteractive"

# Install git, SSH, and other utilities
RUN set -ex \
    && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression \
    && apt-get update \
    && apt install -y -qq apt-transport-https gnupg ca-certificates \
    && apt-get install software-properties-common -y -qq --no-install-recommends \
    && apt-get update \
    && apt-get install -y -qq --no-install-recommends \
        curl jq unzip wget apt-utils tar git vim make \
    && rm -rf /var/lib/apt/lists/*

# Add new repo
RUN add-apt-repository ppa:rmescandon/yq

# Install additional packages
RUN apt update && apt install -y \
    yq \
    && rm -rf /var/lib/apt/lists/*

ENV LC_CTYPE="C.UTF-8"

#=======================End of layer: core  =================

FROM core AS tools

# Install pip
RUN curl -s https://bootstrap.pypa.io/get-pip.py | python3
# Install python packages
RUN pip install python-gitlab

# Install Azure
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN az aks install-cli

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && kubectl version --client

# Install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh
RUN helm plugin install https://github.com/databus23/helm-diff

# Install Helmfile
ARG HELMFILE_VERSION=0.154.0
RUN wget -q -qO- https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz | tar xvz -C /usr/local/bin helmfile

# Install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    chmod ug+s /usr/bin/docker && \
    rm ./get-docker.sh

# Install Node 16
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && node -v

# Install Yarn
RUN npm install --global yarn \
    && yarn --version

# Remove unused files and other
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && apt-get clean