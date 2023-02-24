FROM debian:bullseye-slim

ARG DEBIAN_FRONTEND noninteractive
ARG ANSIBLE_VERSION
ARG YQ_VERSION
ARG KUSTOMIZE_VERSION
ARG HELM_VERSION
ARG AVP_VERSION
ARG YQ_BINARY=yq_linux_amd64

RUN set -eux; \
  echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections; \
  echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections

RUN set -eux; \
  apt-get update; \
  apt-get -y dist-upgrade; \
  apt-get install -y --no-install-recommends locales git curl wget lsb-release gpg apt-transport-https jq python-is-python3 python3-pip python3-psycopg2 python3-mysqldb; \
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null; \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list; \
  apt-get update; \
  apt-get install -y helm=${HELM_VERSION}; \
  apt-get clean all; \
  rm -r /var/lib/apt/lists /var/cache/apt/archives

RUN pip install kubernetes ansible==$ANSIBLE_VERSION ansible-modules-hashivault

RUN set -eux; \
  curl https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} --output /usr/local/bin/yq; \
  chmod +x /usr/local/bin/yq

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash -s ${KUSTOMIZE_VERSION} /usr/local/bin/

RUN set -eux; \
  curl https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v${AVP_VERSION}/argocd-vault-plugin_${AVP_VERSION}_linux_amd64 --output /usr/local/bin/argocd-vault-plugin; \
  chmod +x /usr/local/bin/argocd-vault-plugin

ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US:en'
ENV LC_ALL='en_US.UTF-8'

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
