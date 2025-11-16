#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECONFIG_PATH="$SCRIPT_DIR/kubeconfig/k3s.yaml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

check_kubeconfig() {
    if [ ! -f "$KUBECONFIG_PATH" ]; then
        print_error "Kubeconfig not found at $KUBECONFIG_PATH"
        print_info "Please run './orchestrator.sh create' first"
        exit 1
    fi
    export KUBECONFIG="$KUBECONFIG_PATH"
}

create_cluster() {
    echo "================================================"
    echo "Creating K3s cluster..."
    echo "================================================"
    
    # Check if VMs already exist
    if vagrant status | grep -q "running"; then
        print_info "Cluster already exists. Destroying first..."
        vagrant destroy -f
    fi
    
    # Create VMs and install K3s
    vagrant up
    
    # Wait for cluster to be ready
    sleep 10
    
    # Set kubeconfig
    export KUBECONFIG="$KUBECONFIG_PATH"
    
    # Verify cluster
    echo ""
    print_info "Verifying cluster..."
    kubectl get nodes
    
    echo ""
    print_success "Cluster created successfully!"
    echo ""
    echo "To use kubectl, run:"
    echo "  export KUBECONFIG=$KUBECONFIG_PATH"
    echo ""
}

start_cluster() {
    echo "================================================"
    echo "Starting K3s cluster..."
    echo "================================================"
    
    vagrant up
    
    sleep 10
    check_kubeconfig
    
    echo ""
    print_info "Cluster status:"
    kubectl get nodes
    
    echo ""
    print_success "Cluster started successfully!"
}

stop_cluster() {
    echo "================================================"
    echo "Stopping K3s cluster..."
    echo "================================================"
    
    vagrant halt
    
    print_success "Cluster stopped successfully!"
}

destroy_cluster() {
    echo "================================================"
    echo "Destroying K3s cluster..."
    echo "================================================"
    
    vagrant destroy -f
    
    # Clean up kubeconfig
    rm -rf kubeconfig/
    
    print_success "Cluster destroyed successfully!"
}

deploy_manifests() {
    echo "================================================"
    echo "Deploying applications to cluster..."
    echo "================================================"
    
    check_kubeconfig
    
    # Create namespace
    print_info "Creating namespace..."
    kubectl apply -f manifests/namespaces/
    
    # Create secrets
    print_info "Creating secrets..."
    kubectl apply -f manifests/secrets/
    
    # Create volumes
    print_info "Creating persistent volumes..."
    kubectl apply -f manifests/volumes/
    
    # Deploy databases
    print_info "Deploying databases..."
    kubectl apply -f manifests/databases/
    
    # Wait for databases to be ready
    print_info "Waiting for databases to be ready..."
    kubectl wait --for=condition=ready pod -l app=inventory-db -n microservices --timeout=300s || true
    kubectl wait --for=condition=ready pod -l app=billing-db -n microservices --timeout=300s || true
    
    # Deploy RabbitMQ
    print_info "Deploying RabbitMQ..."
    kubectl apply -f manifests/rabbitmq/
    
    # Wait for RabbitMQ
    print_info "Waiting for RabbitMQ to be ready..."
    kubectl wait --for=condition=ready pod -l app=rabbitmq -n microservices --timeout=300s || true
    
    # Deploy applications
    print_info "Deploying applications..."
    kubectl apply -f manifests/applications/
    
    # Deploy ingress
    print_info "Deploying ingress..."
    kubectl apply -f manifests/ingress/
    
    echo ""
    print_success "All manifests deployed successfully!"
    
    echo ""
    print_info "Checking deployment status..."
    kubectl get all -n microservices
    
    echo ""
    print_info "API Gateway available at: http://192.168.56.100:3000"
}

delete_manifests() {
    echo "================================================"
    echo "Deleting applications from cluster..."
    echo "================================================"
    
    check_kubeconfig
    
    # Delete in reverse order
    kubectl delete -f manifests/ingress/ --ignore-not-found=true
    kubectl delete -f manifests/applications/ --ignore-not-found=true
    kubectl delete -f manifests/rabbitmq/ --ignore-not-found=true
    kubectl delete -f manifests/databases/ --ignore-not-found=true
    kubectl delete -f manifests/volumes/ --ignore-not-found=true
    kubectl delete -f manifests/secrets/ --ignore-not-found=true
    kubectl delete -f manifests/namespaces/ --ignore-not-found=true
    
    print_success "All manifests deleted successfully!"
}

status() {
    echo "================================================"
    echo "Cluster Status"
    echo "================================================"
    
    check_kubeconfig
    
    echo ""
    echo "Nodes:"
    kubectl get nodes
    
    echo ""
    echo "All resources in microservices namespace:"
    kubectl get all -n microservices
    
    echo ""
    echo "Persistent Volumes:"
    kubectl get pv
    
    echo ""
    echo "Persistent Volume Claims:"
    kubectl get pvc -n microservices
}

# Main script
case "$1" in
    create)
        create_cluster
        ;;
    start)
        start_cluster
        ;;
    stop)
        stop_cluster
        ;;
    destroy)
        destroy_cluster
        ;;
    deploy)
        deploy_manifests
        ;;
    delete)
        delete_manifests
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {create|start|stop|destroy|deploy|delete|status}"
        echo ""
        echo "Commands:"
        echo "  create   - Create and start the K3s cluster"
        echo "  start    - Start existing cluster"
        echo "  stop     - Stop the cluster"
        echo "  destroy  - Destroy the cluster completely"
        echo "  deploy   - Deploy all applications to cluster"
        echo "  delete   - Delete all applications from cluster"
        echo "  status   - Show cluster and application status"
        exit 1
        ;;
esac