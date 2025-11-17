#!/bin/bash
set -e

echo "================================================"
echo "Setting up kubectl on host machine..."
echo "================================================"

# Check if kubeconfig exists
if [ ! -f kubeconfig/k3s.yaml ]; then
    echo "Error: kubeconfig/k3s.yaml not found!"
    echo "Please run 'vagrant up' first to create the cluster."
    exit 1
fi

# Set KUBECONFIG environment variable
export KUBECONFIG=$(pwd)/kubeconfig/k3s.yaml

# Test connection
echo ""
echo "Testing connection to cluster..."
kubectl get nodes

echo ""
echo "✓ kubectl configured successfully!"
echo ""
echo "To use kubectl, run:"
echo "  export KUBECONFIG=$(pwd)/kubeconfig/k3s.yaml"
echo ""
echo "Or add to your ~/.bashrc or ~/.zshrc:"
echo "  export KUBECONFIG=$(pwd)/kubeconfig/k3s.yaml"
echo ""