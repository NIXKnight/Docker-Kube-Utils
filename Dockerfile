FROM debian:bullseye-slim

ARG ANSIBLE_VERSION
ARG YQ_VERSION
ARG TERRAFORM_VERSION
ARG YQ_BINARY=yq_linux_amd64

RUN set -eux; \
  apt-get update; \
  DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade; \
  echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections; \
  echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections; \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales git curl wget lsb-release gpg apt-transport-https jq python-is-python3 python3-pip python3-psycopg2 python3-mysqldb; \
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list; \
  apt-get update; \
  DEBIAN_FRONTEND=noninteractive apt-get install -y terraform=$TERRAFORM_VERSION; \
  pip install kubernetes ansible==$ANSIBLE_VERSION ansible-modules-hashivault; \
  curl https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} --output /usr/local/bin/yq; \
  chmod +x /usr/local/bin/yq; \
  rm -r /var/lib/apt/lists /var/cache/apt/archives

ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US:en'
ENV LC_ALL='en_US.UTF-8'

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
