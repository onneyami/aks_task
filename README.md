
# Azure Kubernetes Service (AKS) Dual-OS Architecture & Container Delivery

An enterprise-ready deployment pattern implementing Azure Kubernetes Service (AKS) with heterogeneous compute pools (Linux Ubuntu and Windows Server 2022) backed by Azure Container Registry (ACR), Azure CNI networking, and Azure Policy Gatekeeper governance.

Infrastructure provisioning is automated via Terraform, with container image pipelines managed via ACR cloud tasks and native Kubernetes workload manifests.

---

## Architecture Overview

```
                          ┌────────────────────────────────────────────────────────┐
                          │         Azure Virtual Network: vnet-01 (10.0.0.0/16)    │
                          │                                                        │
                          │  ┌──────────────────────────────────────────────────┐  │
                          │  │           aks-subnet (10.0.0.0/20)               │  │
                          │  │                                                  │  │
┌──────────────────────┐  │  │   ┌──────────────────┐    ┌──────────────────┐   │  │
│  Azure Container     │  │  │   │  Linux Node Pool │    │ Windows Node Pool│   │  │
│  Registry (ACR)      ├──┼──┼──>│   (agentpool)    │    │     (w1pool)     │   │  │
│  Standard SKU        │  │  │   │   Ubuntu OS      │    │  Windows 2022    │   │  │
└──────────────────────┘  │  │   └────────┬─────────┘    └────────┬─────────┘   │  │
                          │  │            │                       │             │  │
                          │  └────────────┼───────────────────────┼─────────────┘  │
                          └───────────────┼───────────────────────┼────────────────┘
                                          │                       │
                                   ┌──────▼──────┐         ┌──────▼──────┐
                                   │  Namespace: │         │  Namespace: │
                                   │  dev-node   │         │  dev-dotnet │
                                   │  (Node.js)  │         │ (.NET Core) │
                                   └─────────────┘         └─────────────┘

```

### Infrastructure Specifications

| Component                    | Resource Name               | Specification / SKU        | Details                                      |
| ---------------------------- | --------------------------- | -------------------------- | -------------------------------------------- |
| **Resource Group**     | `rg-andrei`               | Target pre-existing scope  | Mentor/Shared subscription environment       |
| **Virtual Network**    | `vnet-01`                 | CIDR `10.0.0.0/16`       | Bring-Your-Own-VNet architecture             |
| **Cluster Subnet**     | `aks-subnet`              | CIDR `10.0.0.0/20`       | Dedicated cluster subnet for Azure CNI       |
| **Container Registry** | `newregistryapl<suffix>`  | Standard SKU               | Private container registry with ACR Tasks    |
| **Managed Cluster**    | `aks-01`                  | Azure CNI, Free Tier       | DNS prefix: `aks-01-dns`, Managed Identity |
| **Linux Node Pool**    | `agentpool`               | 1–2 x `Standard_D2s_v3` | System pool, Ubuntu Linux OS                 |
| **Windows Node Pool**  | `w1pool`                  | 1–2 x `Standard_D2s_v3` | User pool, Windows Server 2022 OS            |
| **RBAC / IAM**         | `AcrPull` Role Assignment | Built-in Azure Role        | AKS Kubelet identity bound to ACR scope      |
| **Monitoring**         | `law-aks-01-<suffix>`     | Log Analytics Workspace    | Container Insights integration               |
| **Governance**         | Azure Policy Add-on         | Admission Controller       | OPA Gatekeeper enforcing baseline standards  |

---

## Directory Structure

```text
.
├── acr.tf              # Azure Container Registry and IAM Role Assignments
├── aks.tf              # AKS Cluster, node pools (Linux & Windows), network profiles
├── main.tf             # VNet, Subnet, and shared resource group data source
├── outputs.tf          # Exported connection strings, registry URLs, credentials commands
├── providers.tf        # Provider definitions (azurerm, random)
├── variables.tf        # Input variable definitions and environment defaults
├── manifests/          # Kubernetes workload manifests
│   ├── aks-deployment-l01.yaml   # Linux Node.js Deployment & LoadBalancer Service
│   └── aks-deployment-w01.yaml   # Windows .NET Deployment & LoadBalancer Service
└── src/                # Workload application source code
    ├── image-l01/      # Node.js source and Linux Dockerfile
    └── image-w01/      # .NET Core source and Windows Dockerfile

```

---

## Prerequisites

* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (v2.55.0+)
* [Terraform](https://developer.hashicorp.com/terraform/downloads) (v1.5.0+)
* [kubectl](https://kubernetes.io/docs/tasks/tools/) (v1.28+)
* Authenticated session against target subscription:

```bash
az login
az account set --subscription "c6a76d9c-0f67-4a42-b2a1-3defb05f2aae"

```

---

## Deployment Workflow

### Phase 1: Infrastructure Provisioning (Terraform)

1. Initialize provider plugins and check syntax:

```bash
terraform init
terraform validate

```

2. Review plan and provision the Azure infrastructure:

```bash
terraform plan -out=tfplan
terraform apply tfplan

```

3. Export Terraform outputs into your local shell:

```bash
export ACR_NAME=$(terraform output -raw acr_name)
export ACR_SERVER=$(terraform output -raw acr_login_server)
export CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
export RG_NAME="rg-andrei"

```

4. Fetch cluster credentials for `kubectl`:

```bash
az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME --overwrite-existing
kubectl get nodes -o wide

```

---

### Phase 2: Build & Push Images via ACR Tasks

ACR Tasks run the Docker build daemon entirely in the Azure cloud, enabling cross-platform compilation of Windows and Linux images without local container daemons.

#### 1. Linux Image (`hellofromnode:v1.0`)

```bash
mkdir -p ~/image-l01 && cd ~/image-l01

cat << 'EOF' > server.js
const http = require('http')
const port = 80
const server = http.createServer((request, response) => {
  response.writeHead(200, {'Content-Type': 'text/plain'})
  response.write('Hello World from Node\n')
  response.end('Version: ' + process.env.NODE_VERSION + '\n')
})
server.listen(port)
EOF

cat << 'EOF' > package.json
{
  "name": "helloworld",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": { "start": "node server.js" }
}
EOF

cat << 'EOF' > Dockerfile
FROM node:20.2-alpine
COPY . /src
RUN cd /src && npm install
EXPOSE 80
CMD ["node", "/src/server.js"]
EOF

# Build in ACR
az acr build --registry $ACR_NAME --image hellofromnode:v1.0 .

```

#### 2. Windows Image (`hellofromdotnet:v1.0`)

```bash
mkdir -p ~/image-w01 && cd ~/image-w01
git clone https://github.com/Azure-Samples/dotnetcore-docs-hello-world.git
cd dotnetcore-docs-hello-world

# Build Windows container directly on Azure cloud compute
az acr build --registry $ACR_NAME --image hellofromdotnet:v1.0 --platform windows --file Dockerfile.windows .

```

---

### Phase 3: Application Workload Deployment

#### 1. Create Target Namespaces

```bash
kubectl create namespace dev-node
kubectl create namespace dev-dotnet

```

#### 2. Deploy Linux Application

```bash
cat << EOF | kubectl apply -n dev-node -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hellofromnode-deployment
  labels:
    app: hellofromnode
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hellofromnode
  template:
    metadata:
      labels:
        app: hellofromnode
    spec:
      nodeSelector:
        "kubernetes.io/os": linux
      containers:
      - name: hellofromnode
        image: ${ACR_SERVER}/hellofromnode:v1.0
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 128Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: hellofromnode-service
spec:
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
  selector:
    app: hellofromnode
EOF

```

#### 3. Deploy Windows Application

```bash
cat << EOF | kubectl apply -n dev-dotnet -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hellofromdotnet-deployment
  labels:
    app: hellofromdotnet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hellofromdotnet
  template:
    metadata:
      labels:
        app: hellofromdotnet
    spec:
      nodeSelector:
        "kubernetes.io/os": windows
      containers:
      - name: hellofromdotnet
        image: ${ACR_SERVER}/hellofromdotnet:v1.0
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 128Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: hellofromdotnet-service
spec:
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
  selector:
    app: hellofromdotnet
EOF

```

---

## Verification & Testing

### 1. Pod Node Scheduling Verification

Confirm that workloads were scheduled onto their respective OS pools based on their `nodeSelector`:

```bash
kubectl get pods -n dev-node -o wide
kubectl get pods -n dev-dotnet -o wide

```

### 2. Service Endpoints

Wait for public IP allocation from Azure Load Balancer:

```bash
kubectl get svc -n dev-node
kubectl get svc -n dev-dotnet

```

Query the allocated public IPs:

```bash
NODE_IP=$(kubectl get svc hellofromnode-service -n dev-node -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
DOTNET_IP=$(kubectl get svc hellofromdotnet-service -n dev-dotnet -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl "http://${NODE_IP}"
# Response: Hello World from Node

curl "http://${DOTNET_IP}"
# Response: Hello World from .NET 7

```

---

## Clean-Up & Deprovisioning

> **CRITICAL:** Do **not** execute `az group delete --name rg-andrei`. The resource group is a shared mentor environment.

To destroy all provisioned infrastructure without damaging the host resource group:

```bash
# 1. Delete workloads and release Load Balancer Public IPs
kubectl delete namespace dev-node dev-dotnet

# 2. Destroy managed Azure infrastructure via Terraform
terraform destroy -auto-approve
```

Confirm that no orphaned Azure Managed Disks remain in the subscription:

```bash
az disk list --resource-group rg-andrei --output table
```
