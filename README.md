# Orchestrator - Kubernetes Microservices Deployment

This project deploys a microservices architecture on a K3s Kubernetes cluster using Vagrant. It demonstrates containerization, orchestration, and DevOps practices with a complete CI/CD-ready infrastructure.

## 📋 Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Usage](#usage)
- [Manifests Overview](#manifests-overview)
- [Troubleshooting](#troubleshooting)
- [Technical Details](#technical-details)

## 🏗️ Architecture

The application runs on a **K3s Kubernetes cluster** with 2 nodes:
```
┌─────────────────────────────────────────────────────────────────┐
│                        K3s Cluster                              │
│                                                                 │
│  ┌──────────────────┐          ┌──────────────────┐             │
│  │  Master Node     │          │  Agent Node      │             │
│  │  192.168.56.100  │◄────────►│  192.168.56.101  │             │
│  └──────────────────┘          └──────────────────┘             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Microservices (Namespace)                  │    │
│  │                                                         │    │
│  │  ┌──────────────┐                                       │    │
│  │  │ API Gateway  │ :3000 (Ingress - External Access)     │    │
│  │  │ Deployment   │ (HPA: 1-3 replicas)                   │    │
│  │  └──────┬───────┘                                       │    │
│  │         │                                               │    │
│  │    ┌────┴─────┬──────────────┐                          │    │
│  │    │          │              │                          │    │
│  │ ┌──▼────┐  ┌──▼────┐  ┌─────▼─────┐                     │    │
│  │ │Inventory│ │Billing│ │ RabbitMQ  │                     │    │
│  │ │  App   │ │  App  │  │StatefulSet│                     │    │
│  │ │Deploy  │ │StatefulSet│          │                     │    │
│  │ │HPA 1-3 │ │       │  │           │                     │    │
│  │ └───┬───┘  └───┬───┘  └───────────┘                     │    │
│  │     │           │                                       │    │
│  │ ┌───▼───┐   ┌───▼───┐                                   │    │
│  │ │Inventory│ │Billing│                                   │    │
│  │ │   DB   │  │  DB   │                                   │    │
│  │ │StatefulSet│StatefulSet│                               │    │
│  │ │  +PV   │  │  +PV  │                                   │    │
│  │ └────────┘  └───────┘                                   │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Components:

1. **api-gateway-app** - API Gateway with auto-scaling (1-3 replicas, CPU 60%)
2. **inventory-app** - Inventory service with auto-scaling (1-3 replicas, CPU 60%)
3. **billing-app** - Billing service (StatefulSet for processing RabbitMQ messages)
4. **inventory-db** - PostgreSQL database (StatefulSet with persistent volume)
5. **billing-db** - PostgreSQL database (StatefulSet with persistent volume)
6. **rabbitmq** - Message queue (StatefulSet)

## ✅ Prerequisites

### Required Software:

- **VirtualBox** (7.0+)
- **Vagrant** (2.3+)
- **kubectl** (1.27+)
- **Docker** (for building images)
- **Docker Hub account** (for pushing images)

### Installation:

**Ubuntu/Debian:**
```bash
# VirtualBox
sudo apt-get update
sudo apt-get install virtualbox

# Vagrant
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install vagrant

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**macOS:**
```bash
brew install --cask virtualbox
brew install --cask vagrant
brew install kubectl
```

**Windows:**
- Download [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- Download [Vagrant](https://www.vagrantup.com/downloads)
- Download [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)

### System Requirements:

- **RAM**: Minimum 6GB available (2GB per VM + 2GB for host)
- **CPU**: 2+ cores recommended
- **Disk**: 10GB free space

## 📁 Project Structure
```
orchestrator/
├── README.md                    # This file
├── Vagrantfile                  # VM configuration
├── orchestrator.sh              # Main orchestration script
│
├── scripts/                     # Provisioning scripts
│   ├── install-k3s-master.sh   # K3s master installation
│   ├── install-k3s-agent.sh    # K3s agent installation
│   └── setup-kubectl.sh        # kubectl configuration helper
│
├── manifests/                   # Kubernetes manifests
│   ├── namespaces/
│   │   └── microservices.yaml
│   ├── secrets/
│   │   ├── postgres-secret.yaml
│   │   └── rabbitmq-secret.yaml
│   ├── volumes/
│   │   ├── inventory-db-pvc.yaml
│   │   └── billing-db-pvc.yaml
│   ├── databases/
│   │   ├── inventory-db-statefulset.yaml
│   │   ├── inventory-db-service.yaml
│   │   ├── billing-db-statefulset.yaml
│   │   └── billing-db-service.yaml
│   ├── rabbitmq/
│   │   ├── rabbitmq-statefulset.yaml
│   │   └── rabbitmq-service.yaml
│   ├── applications/
│   │   ├── inventory-app-deployment.yaml
│   │   ├── inventory-app-service.yaml
│   │   ├── inventory-app-hpa.yaml
│   │   ├── billing-app-statefulset.yaml
│   │   ├── billing-app-service.yaml
│   │   ├── api-gateway-deployment.yaml
│   │   ├── api-gateway-service.yaml
│   │   └── api-gateway-hpa.yaml
│   └── ingress/
│       └── api-gateway-ingress.yaml
│
└── kubeconfig/                  # Auto-generated after cluster creation
    ├── k3s.yaml                # kubectl configuration
    └── node-token              # K3s agent join token
```

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/Evgeny311/orchestrator.git
cd orchestrator
```

### 2. Build and Push Docker Images


This project uses pre-built Docker images hosted on Docker Hub. You can either use the existing images or build your own.

### Pre-built Images (Ready to Use)

The following Docker images are publicly available and ready to use:

- **Inventory App**: [`evgeny311/inventory-app:v1.0`](https://hub.docker.com/r/evgeny311/inventory-app)
- **Billing App**: [`evgeny311/billing-app:v1.0`](https://hub.docker.com/r/evgeny311/billing-app)
- **API Gateway**: [`evgeny311/api-gateway-app:v1.0`](https://hub.docker.com/r/evgeny311/api-gateway-app)

**These images are already configured in the Kubernetes manifests and will be pulled automatically during deployment.**

### Option 1: Use Pre-built Images (Recommended for Quick Start)

Simply proceed to [Step 3: Create Kubernetes Secrets](#3-create-kubernetes-secrets) - no additional steps needed!

The Kubernetes manifests are already configured with these images:
```yaml
# manifests/applications/inventory-app-deployment.yaml
image: evgeny311/inventory-app:v1.0

# manifests/applications/billing-app-statefulset.yaml
image: evgeny311/billing-app:v1.0

# manifests/applications/api-gateway-deployment.yaml
image: evgeny311/api-gateway-app:v1.0
```

### Option 2: Build Your Own Images

If you want to build and push your own Docker images:

#### Prerequisites:
- Docker installed and running
- Docker Hub account
- Logged in to Docker Hub: `docker login`

#### Step 2.1: Clone the Application Source Code
```bash
# Clone the play-with-containers repository
git clone https://github.com/Evgeny311/play-with-containers.git
cd play-with-containers
```

#### Step 2.2: Build and Push Images Manually
```bash
cd srcs

# Build and push inventory-app
cd inventory-app
docker build -t yourusername/inventory-app:v1.0 .
docker push yourusername/inventory-app:v1.0

# Build and push billing-app
cd ../billing-app
docker build -t yourusername/billing-app:v1.0 .
docker push yourusername/billing-app:v1.0

# Build and push api-gateway
cd ../api-gateway-app
docker build -t yourusername/api-gateway-app:v1.0 .
docker push yourusername/api-gateway-app:v1.0
```

Replace `yourusername` with your Docker Hub username.

#### Step 2.3: Build and Push Using Helper Script (Automated)

This project includes a helper script for automated building and pushing:
```bash
# Clone both repositories (if not already cloned)
git clone https://github.com/Evgeny311/play-with-containers.git
git clone https://github.com/Evgeny311/orchestrator.git

cd orchestrator

# Create symbolic link to play-with-containers
ln -s ../play-with-containers play-with-containers

# Run the build script
cd build
./build-and-push.sh yourusername v1.0

# Update manifests with your Docker Hub username
./update-manifests.sh yourusername v1.0
```

Replace `yourusername` with your Docker Hub username.

**The script will:**
1. ✅ Build all three Docker images
2. ✅ Tag them with version `v1.0` and `latest`
3. ✅ Push them to your Docker Hub account
4. ✅ Update Kubernetes manifests with your image names

#### Step 2.4: Verify Images on Docker Hub

After building, verify your images are available:
```bash
# List local images
docker images yourusername/*

# Or check on Docker Hub
# https://hub.docker.com/u/yourusername
```

### Pulling Images Manually (For Testing)

If you want to test the images locally:
```bash
docker pull evgeny311/inventory-app:v1.0
docker pull evgeny311/billing-app:v1.0
docker pull evgeny311/api-gateway-app:v1.0

# Run a container for testing
docker run -p 8080:8080 evgeny311/inventory-app:v1.0
```

### Image Specifications

| Image | Base Image | Size | Exposed Port |
|-------|-----------|------|--------------|
| `evgeny311/inventory-app:v1.0` | `python:3.11-alpine` | ~150MB | 8080 |
| `evgeny311/billing-app:v1.0` | `python:3.11-alpine` | ~145MB | 8080 |
| `evgeny311/api-gateway-app:v1.0` | `python:3.11-alpine` | ~140MB | 3000 |

### Using Custom Images

If you built your own images, update the image names in the following manifests:
```bash
# Update all manifests at once
cd build
./update-manifests.sh yourusername v1.0

# Or manually edit each file:
# - manifests/applications/inventory-app-deployment.yaml
# - manifests/applications/billing-app-statefulset.yaml
# - manifests/applications/api-gateway-deployment.yaml
```

Change:
```yaml
image: evgeny311/inventory-app:v1.0
```

To:
```yaml
image: yourusername/inventory-app:v1.0

### 3. Create Kubernetes Secrets

**Edit secrets** in `manifests/secrets/` and encode your credentials:
```bash
# Encode your password
echo -n 'your-password' | base64

# Update manifests/secrets/postgres-secret.yaml
# Update manifests/secrets/rabbitmq-secret.yaml
```

### 4. Create the Cluster
```bash
# Make scripts executable
chmod +x orchestrator.sh
chmod +x scripts/*.sh

# Create K3s cluster (takes 5-10 minutes)
./orchestrator.sh create
```

### 5. Configure kubectl
```bash
# Set KUBECONFIG environment variable
export KUBECONFIG=$(pwd)/kubeconfig/k3s.yaml

# Verify cluster
kubectl get nodes
```

Expected output:
```
NAME         STATUS   ROLES                  AGE   VERSION
k3s-master   Ready    control-plane,master   2m    v1.27.x+k3s1
k3s-agent    Ready    <none>                 1m    v1.27.x+k3s1
```

### 6. Deploy Applications
```bash
# Deploy all microservices
./orchestrator.sh deploy

# Check deployment status
./orchestrator.sh status
```

### 7. Access the Application
```bash
# API Gateway is available at:
http://192.168.56.100:3000

# Test the API
curl http://192.168.56.100:3000/health
curl http://192.168.56.100:3000/api/movies
```

## 📖 Usage

### Orchestrator Commands
```bash
# Cluster Management
./orchestrator.sh create    # Create and start the cluster
./orchestrator.sh start     # Start existing cluster
./orchestrator.sh stop      # Stop the cluster (preserves data)
./orchestrator.sh destroy   # Destroy cluster completely

# Application Management
./orchestrator.sh deploy    # Deploy all applications
./orchestrator.sh delete    # Delete all applications
./orchestrator.sh status    # Show cluster and app status
```

### kubectl Commands
```bash
# Set kubeconfig (add to ~/.bashrc for persistence)
export KUBECONFIG=$(pwd)/kubeconfig/k3s.yaml

# View all resources
kubectl get all -n microservices

# View pods
kubectl get pods -n microservices

# View services
kubectl get svc -n microservices

# View deployments
kubectl get deployments -n microservices

# View statefulsets
kubectl get statefulsets -n microservices

# View HPA (Horizontal Pod Autoscaler)
kubectl get hpa -n microservices

# View logs
kubectl logs -f <pod-name> -n microservices

# Describe a resource
kubectl describe pod <pod-name> -n microservices

# Execute command in pod
kubectl exec -it <pod-name> -n microservices -- /bin/sh

# Port forward (for debugging)
kubectl port-forward svc/api-gateway-service 3000:3000 -n microservices
```

### Scaling Applications
```bash
# Manual scaling (if HPA is disabled)
kubectl scale deployment inventory-app --replicas=3 -n microservices

# View HPA status
kubectl get hpa -n microservices

# Edit HPA
kubectl edit hpa inventory-app-hpa -n microservices
```

## 📚 Manifests Overview

### Namespace
- Creates `microservices` namespace for all resources

### Secrets
- **postgres-secret**: Database credentials (base64 encoded)
- **rabbitmq-secret**: RabbitMQ credentials (base64 encoded)

### Persistent Volumes
- **inventory-db-pvc**: 5Gi storage for inventory database
- **billing-db-pvc**: 5Gi storage for billing database

### Databases (StatefulSets)
- **inventory-db**: PostgreSQL 16 with persistent storage
- **billing-db**: PostgreSQL 16 with persistent storage

### RabbitMQ (StatefulSet)
- Message queue for async order processing

### Applications

**Deployments with HPA:**
- **api-gateway**: 1-3 replicas, scales at 60% CPU
- **inventory-app**: 1-3 replicas, scales at 60% CPU

**StatefulSet:**
- **billing-app**: 1 replica (message consumer)

### Services
- ClusterIP services for internal communication
- NodePort service for API Gateway external access

### Ingress
- Routes external traffic to API Gateway

## 🔧 Troubleshooting

### Cluster Issues

**Problem**: Nodes not ready
```bash
# Check node status
kubectl get nodes

# Describe node
kubectl describe node k3s-master

# Check K3s service on master
vagrant ssh master -c "sudo systemctl status k3s"

# Check K3s agent on agent
vagrant ssh agent -c "sudo systemctl status k3s-agent"
```

**Problem**: Cannot connect to cluster
```bash
# Verify kubeconfig
ls -la kubeconfig/k3s.yaml

# Re-export kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig/k3s.yaml

# Test connection
kubectl cluster-info
```

### Pod Issues

**Problem**: Pod stuck in Pending
```bash
# Check pod events
kubectl describe pod <pod-name> -n microservices

# Check PVC status
kubectl get pvc -n microservices

# Check if nodes have enough resources
kubectl describe nodes
```

**Problem**: Pod CrashLoopBackOff
```bash
# Check pod logs
kubectl logs <pod-name> -n microservices

# Check previous logs
kubectl logs <pod-name> -n microservices --previous

# Describe pod
kubectl describe pod <pod-name> -n microservices
```

**Problem**: ImagePullBackOff
```bash
# Check if image exists on Docker Hub
docker pull yourusername/inventory-app:v1.0

# Verify image name in deployment
kubectl get deployment inventory-app -n microservices -o yaml | grep image
```

### Database Connection Issues
```bash
# Check if database pod is running
kubectl get pods -l app=inventory-db -n microservices

# Test database connection
kubectl exec -it inventory-db-0 -n microservices -- psql -U postgres -d inventory_db

# Check database service
kubectl get svc inventory-db-service -n microservices
```

### RabbitMQ Issues
```bash
# Check RabbitMQ pod
kubectl get pods -l app=rabbitmq -n microservices

# View RabbitMQ logs
kubectl logs rabbitmq-0 -n microservices

# Access RabbitMQ management (if enabled)
kubectl port-forward svc/rabbitmq-service 15672:15672 -n microservices
# Then open: http://localhost:15672
```

### HPA Not Working
```bash
# Check metrics server
kubectl get deployment metrics-server -n kube-system

# Install metrics server if missing
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check HPA status
kubectl get hpa -n microservices
kubectl describe hpa inventory-app-hpa -n microservices
```

### Complete Reset
```bash
# Delete everything and start fresh
./orchestrator.sh delete
./orchestrator.sh destroy
./orchestrator.sh create
./orchestrator.sh deploy
```
### VirtualBox and Hyper-V Conflict

If you're using WSL2 on Windows, you may encounter issues with VirtualBox and Hyper-V.

**Solution:**
- Use VirtualBox 7.0+ which supports Hyper-V backend
- Or temporarily disable Hyper-V (not recommended, breaks WSL2):
```powershell
  bcdedit /set hypervisorlaunchtype off
  # Reboot required
```

**Network Interface Issue:**
If K3s fails with "unable to find interface eth1", update the scripts to use the correct interface:
- In `scripts/install-k3s-master.sh` and `scripts/install-k3s-agent.sh`
- Change `--flannel-iface eth1` to `--flannel-iface enp0s8`

## 🔍 Technical Details

### K3s Cluster Configuration

- **Master Node**: 192.168.56.100 (2GB RAM, 2 CPUs)
- **Agent Node**: 192.168.56.101 (2GB RAM, 2 CPUs)
- **CNI**: Flannel (default)
- **Ingress**: Traefik disabled (using custom ingress)
- **Storage**: Local path provisioner (default)

### Resource Limits

**Databases:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

**Applications:**
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Horizontal Pod Autoscaling (HPA)

- **Metric**: CPU utilization
- **Target**: 60%
- **Min Replicas**: 1
- **Max Replicas**: 3
- **Scale Up**: When CPU > 60% for 30s
- **Scale Down**: When CPU < 60% for 5m

### Persistent Storage

- **Storage Class**: local-path (K3s default)
- **Access Mode**: ReadWriteOnce
- **Reclaim Policy**: Retain
- **Volume Size**: 5Gi per database

### Network Policies

All services communicate within the `microservices` namespace:
- Internal communication via ClusterIP services
- External access only through API Gateway (NodePort 30000)

### Security

- Secrets are base64 encoded (not encrypted)
- For production: use sealed-secrets, Vault, or cloud KMS
- Network policies can be added for additional isolation
- RBAC is enabled by default in K3s

## 📝 Best Practices

### For Development:
1. Use specific image tags (not `latest`)
2. Always check logs when debugging: `kubectl logs -f <pod>`
3. Use `kubectl describe` to see events
4. Test locally before pushing to Docker Hub

### For Production:
1. Use proper secrets management (Vault, sealed-secrets)
2. Implement network policies
3. Add resource quotas
4. Set up monitoring (Prometheus/Grafana)
5. Configure backup strategy for databases
6. Use rolling updates for zero-downtime deployments
7. Implement health checks (liveness/readiness probes)

## 🎓 Learning Resources

- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Patterns](https://www.oreilly.com/library/view/kubernetes-patterns/9781492050278/)

## 📄 License

This project is part of the **Kood/Jõhvi** DevOps curriculum.

## 👥 Author

#eandreyc

---

## 🎯 What's Next?

After completing this project, consider:
1. **Kubernetes Certification** (CKA/CKAD)
2. **GitOps** with ArgoCD or FluxCD
3. **Service Mesh** with Istio or Linkerd
4. **Monitoring** with Prometheus and Grafana
5. **Cloud Kubernetes** (EKS, GKE, AKS)

---

**Note**: This project demonstrates microservices orchestration on Kubernetes, implementing industry-standard practices for container orchestration, auto-scaling, persistent storage, and service discovery.