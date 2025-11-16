#!/bin/bash
set -e

DOCKER_USERNAME="${1}"
VERSION="${2:-v1.0}"

if [ -z "$DOCKER_USERNAME" ]; then
    echo "Usage: $0 <docker-username> [version]"
    echo "Example: $0 myusername v1.0"
    exit 1
fi

echo "Updating manifests with Docker username: $DOCKER_USERNAME"
echo "Version: $VERSION"

# Update all deployment/statefulset manifests
find manifests/applications -name "*.yaml" -type f -exec sed -i.bak \
    -e "s|image: yourusername/|image: ${DOCKER_USERNAME}/|g" \
    -e "s|:v[0-9.]*|:${VERSION}|g" {} \;

# Remove backup files
find manifests/applications -name "*.bak" -type f -delete

echo "✓ Manifests updated successfully!"
echo ""
echo "Updated files:"
ls -la manifests/applications/*.yaml