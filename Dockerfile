FROM debian:bookworm-slim AS minimal-system

ARG DEBIAN_FRONTEND=noninteractive
ARG ANSIBLE_VERSION
ARG YQ_VERSION
ARG KUSTOMIZE_VERSION
ARG HELM_VERSION
ARG AVP_VERSION
ARG YQ_BINARY=yq_linux_amd64

ARG USER=999

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US:en'
ENV LC_ALL='en_US.UTF-8'

ENV VIRTUAL_ENV="/opt/kube_utils_venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

ENV ANSIBLE_STDOUT_CALLBACK="debug"
ENV ANSIBLE_CALLBACKS_ENABLED="profile_tasks"

SHELL ["/bin/bash", "-euxco", "pipefail"]

RUN \
    groupadd -g ${USER} user; \
    useradd -m -d /home/user -r -u ${USER} -g user user

RUN \
    echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections; \
    echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections

RUN \
    apt-get update; \
    apt-get -y dist-upgrade; \
    apt-get install -y --no-install-recommends \
        locales \
        git \
        curl \
        wget \
        jq \
        lsb-release \
        python-is-python3 \
        python3-pip \
        python3-venv \
        libmariadb3 \
        libpq5; \
    rm -r /var/lib/apt/lists /var/cache/apt/archives; \
    find /usr/lib/python3 -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true

FROM minimal-system as builder

RUN \
    apt-get update; \
    apt-get -y dist-upgrade; \
    apt-get install -y --no-install-recommends \
        python3-dev \
        pkg-config \
        build-essential \
        libmariadb-dev \
        libpq-dev

RUN python -m venv "${VIRTUAL_ENV}"; \
    # Install Ansible and Python Kubernetes module
    pip install --no-cache-dir --no-compile kubernetes ansible==$ANSIBLE_VERSION psycopg2 mysqlclient;

FROM minimal-system as base

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

RUN \
    # Install yq
    curl https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} --output /usr/local/bin/yq; \
    chmod +x /usr/local/bin/yq; \
    # Install kustomize
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash -s ${KUSTOMIZE_VERSION} /usr/local/bin/; \
    # Install argocd-vault-plugin
    curl --location https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v${AVP_VERSION}/argocd-vault-plugin_${AVP_VERSION}_linux_amd64 --output /usr/local/bin/argocd-vault-plugin; \
    chmod +x /usr/local/bin/argocd-vault-plugin; \
    # Install helm
    curl --location https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz --output /tmp/helm-linux-amd64.tar.gz; \
    cd /tmp; \
    tar zxf helm-linux-amd64.tar.gz; \
    mv linux-amd64/helm /usr/local/bin/helm; \
    rm -rf linux-amd64 /tmp/helm-linux-amd64.tar.gz

ENV HELM_CACHE_HOME=/home/user/.helm
ENV HELM_CONFIG_HOME=/home/user/.helm
ENV HELM_DATA_HOME=/home/user/.helm

ENV USER=user
USER $USER
WORKDIR /home/user
