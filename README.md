# Gist API EKS Deployment

A production-ready HTTP API that fetches GitHub Gists for a user, deployed to AWS EKS.

## Architecture

- **API**: FastAPI application fetching Gists from GitHub API
- **Container**: Docker image stored in Amazon ECR
- **Infrastructure**: VPC, EKS cluster, node groups provisioned via Terraform
- **Deployment**: Kubernetes with Kustomize overlays for dev/prod environments
- **CI/CD**: Jenkins pipeline for automated testing and deployment
- **Load Balancer**: AWS Load Balancer for external access

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Docker
- kubectl
- Git Bash or PowerShell (Windows) / Bash (Linux/Mac)

## Project Structure

```
gist-api-eks/
├── app/                    # FastAPI application
│   ├── main.py
│   └── requirements.txt
├── docker/
│   └── Dockerfile
├── k8s/
│   ├── base/              # Base Kubernetes manifests
│   └── overlays/          # Environment-specific configs (dev/prod)
├── terraform/             # Infrastructure as Code
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       └── ecr/
├── scripts/               # Deployment scripts
├── tests/                 # Unit tests
└── jenkins/               # CI/CD pipeline
```

## Deployment Steps

### Step 1: Provision Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (takes ~10-15 minutes)
terraform apply
```

Save the outputs:
```
ecr_repository_url = "206025053449.dkr.ecr.us-east-1.amazonaws.com/gist-api"
eks_cluster_endpoint = "https://xxxxx.gr7.us-east-1.eks.amazonaws.com"
eks_cluster_name = "gist-api-eks"
vpc_id = "vpc-xxxxxxxxx"
```

### Step 2: Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name gist-api-eks

# Verify connection
kubectl get nodes
```

Expected output:
```
NAME                         STATUS   ROLES    AGE   VERSION
ip-10-0-3-xxx.ec2.internal   Ready    <none>   5m    v1.34.x
ip-10-0-4-xxx.ec2.internal   Ready    <none>   5m    v1.34.x
```

### Step 3: Build and Push Docker Image

**For Linux/Mac:**
```bash
cd ..  # Back to project root
./scripts/build.sh
```

**For Windows (PowerShell):**
```powershell
# Build image
docker build -t gist-api -f docker/Dockerfile .

# Get ECR URL from Terraform output
cd terraform
$ECR_REPO = terraform output -raw ecr_repository_url
cd ..

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO

# Tag and push
docker tag gist-api:latest ${ECR_REPO}:latest
docker push ${ECR_REPO}:latest
```

### Step 4: Update Kubernetes Manifests

Update `k8s/base/deployment.yaml` with your ECR URL:
```yaml
image: <YOUR_ECR_REPO_URL>:latest
# Example: 206025053449.dkr.ecr.us-east-1.amazonaws.com/gist-api:latest
```

Ensure `k8s/base/kustomization.yaml` has:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - configmap.yaml
  - deployment.yaml
  - service.yaml
  - hpa.yaml
  - ingress.yaml
```

### Step 5: Deploy to Dev Environment

```bash
kubectl apply -k k8s/overlays/dev
```

Expected output:
```
namespace/gist-api-dev created
configmap/gist-api-config created
service/gist-api-service created
deployment.apps/gist-api created
horizontalpodautoscaler.autoscaling/gist-api-hpa created
ingress.networking.k8s.io/gist-api-ingress created
```

### Step 6: Verify Deployment

```bash
# Check pods are running
kubectl get pods -n gist-api-dev

# Check service
kubectl get svc -n gist-api-dev
```

Expected output:
```
NAME                        READY   STATUS    RESTARTS   AGE
gist-api-xxxxxxxxx-xxxxx    1/1     Running   0          30s

NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
gist-api-service   ClusterIP   172.20.x.x     <none>        8080/TCP   30s
```

### Step 7: Expose via Load Balancer

```bash
kubectl patch svc gist-api-service -n gist-api-dev -p '{"spec": {"type": "LoadBalancer"}}'

# Wait 1-2 minutes for ELB provisioning, then get the external DNS
kubectl get svc -n gist-api-dev
```

Expected output:
```
NAME               TYPE           CLUSTER-IP     EXTERNAL-IP                                                              PORT(S)          AGE
gist-api-service   LoadBalancer   172.20.x.x     axxxxxxx-xxxxxxxxxx.us-east-1.elb.amazonaws.com                          8080:31xxx/TCP   2m
```

### Step 8: Test the API

**Option 1: Via Load Balancer DNS**
```bash
curl http://<ELB-DNS>:8080/octocat
```

**Option 2: Via Port Forward (if DNS issues)**
```bash
kubectl port-forward svc/gist-api-service 8080:8080 -n gist-api-dev

# In another terminal
curl http://localhost:8080/octocat
```

**Option 3: Via ELB IP directly**
```bash
# Get ELB IP from inside the cluster
kubectl exec -it <pod-name> -n gist-api-dev -- getent hosts <ELB-DNS>

# Use the IP
curl http://<ELB-IP>:8080/octocat
```

Expected response:
```json
{
  "gists": [
    "https://gist.github.com/octocat/6cad326836d38bd3a7ae",
    "https://gist.github.com/octocat/0831f3fbd83ac4d46451",
    ...
  ]
}
```

## API Usage

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/{username}` | Returns list of user's public Gists |

**Examples:**
```bash
curl http://<ELB-DNS>:8080/octocat
curl http://<ELB-DNS>:8080/defunkt
curl http://<ELB-DNS>:8080/torvalds
```

## Deploy to Production

```bash
kubectl apply -k k8s/overlays/prod

# Verify
kubectl get pods -n gist-api-prod
kubectl get svc -n gist-api-prod
```

## Running Tests

```bash
# Install test dependencies
pip install pytest httpx

# Run tests
python -m pytest -v
```

## Validation Script

```bash
chmod +x scripts/validate.sh
./scripts/validate.sh dev
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                           AWS Cloud                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                      VPC (10.0.0.0/16)                     │  │
│  │                                                            │  │
│  │   ┌─────────────────┐       ┌─────────────────┐           │  │
│  │   │  Public Subnet  │       │  Public Subnet  │           │  │
│  │   │   us-east-1a    │       │   us-east-1b    │           │  │
│  │   │  (10.0.1.0/24)  │       │  (10.0.2.0/24)  │           │  │
│  │   └────────┬────────┘       └────────┬────────┘           │  │
│  │            │                         │                     │  │
│  │            └──────────┬──────────────┘                     │  │
│  │                       │                                    │  │
│  │              ┌────────▼────────┐                           │  │
│  │              │   ELB (Public)  │◄──── Internet             │  │
│  │              └────────┬────────┘                           │  │
│  │                       │                                    │  │
│  │   ┌─────────────────┐ │ ┌─────────────────┐               │  │
│  │   │ Private Subnet  │ │ │ Private Subnet  │               │  │
│  │   │   us-east-1a    │ │ │   us-east-1b    │               │  │
│  │   │  (10.0.3.0/24)  │ │ │  (10.0.4.0/24)  │               │  │
│  │   │                 │ │ │                 │               │  │
│  │   │  ┌───────────┐  │ │ │  ┌───────────┐  │               │  │
│  │   │  │EKS Node 1 │◄─┼─┼─┼─►│EKS Node 2 │  │               │  │
│  │   │  │  (Pod)    │  │   │  │  (Pod)    │  │               │  │
│  │   │  └───────────┘  │   │  └───────────┘  │               │  │
│  │   └─────────────────┘   └─────────────────┘               │  │
│  │                                                            │  │
│  │   ┌─────────────────┐                                      │  │
│  │   │      ECR        │  Container Registry                  │  │
│  │   └─────────────────┘                                      │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## CI/CD Pipeline (Jenkins)

The Jenkinsfile automates:
1. **Checkout** - Pull code from repository
2. **Test** - Run pytest unit tests
3. **Build** - Build Docker image and push to ECR
4. **Deploy Dev** - Deploy to dev environment
5. **Validate Dev** - Run validation tests
6. **Deploy Prod** - Deploy to production (main branch only)

## Cleanup

To avoid AWS charges, destroy all resources:

```bash
# Delete Kubernetes resources
kubectl delete -k k8s/overlays/dev
kubectl delete -k k8s/overlays/prod

# Destroy infrastructure
cd terraform
terraform destroy
```

## Troubleshooting

### DNS resolution issues
- Try accessing via ELB IP directly
- Use `kubectl port-forward` for local testing

## Technologies Used

- **Application**: Python, FastAPI, Uvicorn
- **Container**: Docker
- **Orchestration**: Kubernetes, Kustomize
- **Infrastructure**: Terraform, AWS (VPC, EKS, ECR, ELB)
- **CI/CD**: Jenkins