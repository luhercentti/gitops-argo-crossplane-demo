#!/bin/bash

set -e

echo "🗑️ Cleaning up GitOps demo resources..."

# Delete ArgoCD applications (this will cascade delete managed resources)
echo "Deleting ArgoCD applications..."
kubectl delete application --all -n argocd 2>/dev/null || true

# Wait for applications to be deleted
echo "Waiting for applications to be cleaned up..."
sleep 10

# Delete Crossplane claims
echo "Deleting Crossplane claims..."
kubectl delete database --all --all-namespaces 2>/dev/null || true
kubectl delete network --all --all-namespaces 2>/dev/null || true
kubectl delete bucket --all --all-namespaces 2>/dev/null || true

# Delete compositions and XRDs
echo "Deleting Crossplane compositions..."
kubectl delete composition --all 2>/dev/null || true
kubectl delete xrd --all 2>/dev/null || true

# Delete providers
echo "Deleting Crossplane providers..."
kubectl delete provider --all 2>/dev/null || true

# Uninstall Crossplane
echo "Uninstalling Crossplane..."
helm uninstall crossplane -n crossplane-system 2>/dev/null || true

# Uninstall ArgoCD
echo "Uninstalling ArgoCD..."
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 2>/dev/null || true

# Delete namespaces
echo "Deleting namespaces..."
kubectl delete namespace argocd 2>/dev/null || true
kubectl delete namespace crossplane-system 2>/dev/null || true
kubectl delete namespace dev 2>/dev/null || true
kubectl delete namespace staging 2>/dev/null || true
kubectl delete namespace prod 2>/dev/null || true

echo "✅ Cleanup complete!"
echo ""
echo "⚠️ Note: Cloud resources (AWS RDS, S3, etc.) may take some time to be deleted."
echo "Check your cloud provider console to verify all resources are removed."
