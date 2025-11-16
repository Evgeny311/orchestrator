#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Configuration
DOCKER_USERNAME="${1:-yourusername}"
VERSION="${2:-v1.0}"
APPS_PATH="../play-with-containers/srcs"

if [ "$DOCKER_USERNAME" = "yourusername" ]; then
    print_error "Please provide your Docker Hub username"
    echo "Usage: $0 <docker-username> [version]"
    echo "Example: $0 myusername v1.0"
    exit 1
fi

echo "================================================"
echo "Building and pushing Docker images"
echo "================================================"
echo "Docker Hub user: $DOCKER_USERNAME"
echo "Version tag: $VERSION"
echo "Apps path: $APPS_PATH"
echo ""

# Check if apps path exists
if [ ! -d "$APPS_PATH" ]; then
    print_error "Apps path not found: $APPS_PATH"
    print_info "Please adjust APPS_PATH in this script or create symbolic link"
    exit 1
fi

# Build and push inventory-app
echo "Building inventory-app..."
docker build -t ${DOCKER_USERNAME}/inventory-app:${VERSION} ${APPS_PATH}/inventory-app
docker tag ${DOCKER_USERNAME}/inventory-app:${VERSION} ${DOCKER_USERNAME}/inventory-app:latest

print_success "Built inventory-app"

echo "Pushing inventory-app..."
docker push ${DOCKER_USERNAME}/inventory-app:${VERSION}
docker push ${DOCKER_USERNAME}/inventory-app:latest

print_success "Pushed inventory-app"
echo ""

# Build and push billing-app
echo "Building billing-app..."
docker build -t ${DOCKER_USERNAME}/billing-app:${VERSION} ${APPS_PATH}/billing-app
docker tag ${DOCKER_USERNAME}/billing-app:${VERSION} ${DOCKER_USERNAME}/billing-app:latest

print_success "Built billing-app"

echo "Pushing billing-app..."
docker push ${DOCKER_USERNAME}/billing-app:${VERSION}
docker push ${DOCKER_USERNAME}/billing-app:latest

print_success "Pushed billing-app"
echo ""

# Build and push api-gateway
echo "Building api-gateway-app..."
docker build -t ${DOCKER_USERNAME}/api-gateway-app:${VERSION} ${APPS_PATH}/api-gateway-app
docker tag ${DOCKER_USERNAME}/api-gateway-app:${VERSION} ${DOCKER_USERNAME}/api-gateway-app:latest

print_success "Built api-gateway-app"

echo "Pushing api-gateway-app..."
docker push ${DOCKER_USERNAME}/api-gateway-app:${VERSION}
docker push ${DOCKER_USERNAME}/api-gateway-app:latest

print_success "Pushed api-gateway-app"
echo ""

echo "================================================"
print_success "All images built and pushed successfully!"
echo "================================================"
echo ""
echo "Update manifests with these images:"
echo "  ${DOCKER_USERNAME}/inventory-app:${VERSION}"
echo "  ${DOCKER_USERNAME}/billing-app:${VERSION}"
echo "  ${DOCKER_USERNAME}/api-gateway-app:${VERSION}"
echo ""
echo "Or run:"
echo "  sed -i 's|yourusername|${DOCKER_USERNAME}|g' manifests/applications/*.yaml"
echo "  sed -i 's|v1.0|${VERSION}|g' manifests/applications/*.yaml"