#!/bin/bash

set -e

echo "🚀 Installing ArgoCD..."

# Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD using server-side apply to avoid annotation size limits
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side --force-conflicts

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "✅ ArgoCD installed successfully!"
echo ""
echo "📝 To access ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "🔑 Get admin password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo"
echo ""
echo "🌐 Login URL: https://localhost:8080"
echo "   Username: admin"
