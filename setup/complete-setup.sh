#!/bin/bash

set -e

echo "🎯 GitOps Demo Setup - Complete Installation"
echo "=============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Create namespaces
echo "📦 Creating namespaces..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
echo ""

# Install ArgoCD
echo "🚀 Installing ArgoCD..."
./setup/install-argocd.sh
echo ""

# Install Crossplane
echo "🔧 Installing Crossplane..."
./setup/install-crossplane.sh
echo ""

# Wait for Crossplane to be ready
echo "⏳ Waiting for Crossplane to be fully ready..."
sleep 30
echo ""

# Configure providers
echo "⚙️ Configuring Crossplane providers..."
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    ./setup/configure-providers.sh
else
    echo "${YELLOW}⚠️ AWS credentials not set. Skipping provider configuration.${NC}"
    echo "Run './setup/configure-providers.sh' after setting AWS credentials"
fi
echo ""

# Deploy ArgoCD applications
echo "🎯 Deploying demo applications with ArgoCD..."
echo "Note: Update the repository URL in bootstrap/app-of-apps.yaml first!"
read -p "Have you updated the repository URL? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl apply -f bootstrap/app-of-apps.yaml
    echo "${GREEN}✅ ArgoCD applications deployed!${NC}"
else
    echo "${YELLOW}⚠️ Please update the repository URL and run:${NC}"
    echo "   kubectl apply -f bootstrap/app-of-apps.yaml"
fi
echo ""

# Get ArgoCD password
echo "🔑 ArgoCD Admin Password:"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
if [ -n "$ARGOCD_PASSWORD" ]; then
    echo "$ARGOCD_PASSWORD"
else
    echo "Password secret not yet available. Wait a moment and run:"
    echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
fi
echo ""

echo "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "📝 Next steps:"
echo "1. Port-forward ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "2. Access ArgoCD at: https://localhost:8080"
echo "   Username: admin"
echo "   Password: (shown above)"
echo ""
echo "3. Watch resources being created:"
echo "   kubectl get applications -n argocd"
echo "   kubectl get managed -n crossplane-system"
echo ""
echo "4. Check application status:"
echo "   kubectl get pods -n dev"
echo ""
