# **Docker-Kube-Utils**

Dockerfile for custom utilities required in Kubernetes.

## **Usage**

Build Docker image as follows:
```console
docker build --no-cache \
  --build-arg ANSIBLE_VERSION=11.1.0 \
  --build-arg YQ_VERSION=v4.44.6 \
  --build-arg KUSTOMIZE_VERSION=5.5.0 \
  --build-arg HELM_VERSION=3.16.4 \
  --build-arg AVP_VERSION=1.18.1 \
  -t kube-utils:latest .
```
## **Author**

[Saad Ali](https://github.com/nixknight)
