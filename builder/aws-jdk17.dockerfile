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

# Install AWS CLI v2
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /opt \
    && /opt/aws/install --update -i /usr/local/aws-cli -b /usr/local/bin \
    && rm /tmp/awscliv2.zip \
    && rm -rf /opt/aws \
    && aws --version

# Install pip
RUN curl -s https://bootstrap.pypa.io/get-pip.py | python3
# Install python packages
RUN pip install python-gitlab

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

# Install JAVA
ARG JAVA_VERSION=17
RUN apt install -y openjdk-${JAVA_VERSION}-jre-headless

# Install MVN
ARG MAVEN_HOME="/opt/maven"
ARG MAVEN_VERSION=3.9.6

ARG MAVEN_CONFIG_HOME="/root/.m2"

RUN set -ex \
    # Install Maven
    && mkdir -p $MAVEN_HOME \
    && curl -LSso /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && tar xzf /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C $MAVEN_HOME --strip-components=1 \
    && rm /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && update-alternatives --install /usr/bin/mvn mvn /opt/maven/bin/mvn 10000 \
    && mkdir -p $MAVEN_CONFIG_HOME

# Remove unused files and other
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && apt-get clean \
