#!/bin/bash
set -e

echo "================================================"
echo "Installing K3s Agent Node..."
echo "================================================"

# Update system
apt-get update -y

# Wait for master to be ready and token to be available
echo "Waiting for master node token..."
until [ -f /vagrant/kubeconfig/node-token ]; do
  echo "Token not found yet, waiting..."
  sleep 5
done

# Read the token
K3S_TOKEN=$(cat /vagrant/kubeconfig/node-token)
K3S_URL="https://192.168.56.100:6443"

echo "Joining cluster at $K3S_URL"

# Install K3s agent
curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -s - agent \
  --node-name k3s-agent \
  --node-ip 192.168.56.101 \
  --flannel-iface enp0s8

# Wait for agent to join
echo "Waiting for agent to join cluster..."
sleep 10

echo ""
echo "✓ K3s Agent installed successfully!"
echo "  Node: k3s-agent"
echo "  IP: 192.168.56.101"
echo ""