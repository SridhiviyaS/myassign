#!/bin/bash
set -e

ENV=$1
if [ -z "$ENV" ]; then
  echo "Usage: $0 <env> (dev or prod)"
  exit 1
fi

# Update Kustomization with ECR URL
ECR_REPO=$(terraform output -raw ecr_repository_url)
sed -i "s|<ECR_REPO_URL>|$ECR_REPO|g" k8s/base/kustomization.yaml

# Deploy using Kustomize
kubectl apply -k k8s/overlays/$ENV

echo "Deployed to $ENV environment"