#!/bin/bash
set -e

# Build Docker image
docker build -t gist-api -f docker/Dockerfile .

# Get ECR repo URL from Terraform output
ECR_REPO=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO

# Tag and push
docker tag gist-api:latest $ECR_REPO:latest
docker push $ECR_REPO:latest

echo "Image pushed to $ECR_REPO:latest"