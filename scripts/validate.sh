#!/bin/bash
set -e

ENV=$1
if [ -z "$ENV" ]; then
  echo "Usage: $0 <env> (dev or prod)"
  exit 1
fi

# Check pods
kubectl get pods -n gist-api-$ENV

# Check service
kubectl get svc -n gist-api-$ENV

# Test endpoint
SERVICE_IP=$(kubectl get svc gist-api-service -n gist-api-$ENV -o jsonpath='{.spec.clusterIP}')
curl http://$SERVICE_IP:8080/octocat

echo "Validation complete"