#!/bin/bash

set -e

echo "🔧 Installing Crossplane..."

# Create namespace
kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -

# Add Crossplane Helm repository
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane
helm upgrade --install crossplane \
  crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace \
  --wait

# Wait for Crossplane to be ready
echo "⏳ Waiting for Crossplane to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/crossplane -n crossplane-system

echo "✅ Crossplane installed successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Configure cloud provider credentials"
echo "   2. Install providers: ./setup/configure-providers.sh"
echo ""
echo "🔍 Check Crossplane status:"
echo "   kubectl get pods -n crossplane-system"
