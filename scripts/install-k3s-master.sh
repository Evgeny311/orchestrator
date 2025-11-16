#!/bin/bash
set -e

echo "================================================"
echo "Installing K3s Master Node..."
echo "================================================"

# Update system
apt-get update -y

# Install K3s master
curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode 644 \
  --node-name k3s-master \
  --bind-address 192.168.56.100 \
  --advertise-address 192.168.56.100 \
  --node-ip 192.168.56.100 \
  --flannel-iface eth1 \
  --disable traefik

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
sleep 10

# Check K3s status
systemctl status k3s --no-pager || true

# Verify node is ready
until kubectl get nodes | grep -q "Ready"; do
  echo "Waiting for node to be ready..."
  sleep 5
done

echo ""
echo "✓ K3s Master installed successfully!"
echo "  Node: k3s-master"
echo "  IP: 192.168.56.100"
echo ""

# Display node info
kubectl get nodes