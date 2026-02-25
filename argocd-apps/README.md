# ArgoCD Applications

This directory contains ArgoCD Application manifests that define what should be deployed and where.

## Applications

### infrastructure-app.yaml
Deploys all Crossplane infrastructure resources including:
- Provider configurations
- Composite Resource Definitions (XRDs)
- Compositions
- Infrastructure claims (databases, networks, storage)

### backend-app.yaml
Deploys the backend application service including:
- Deployment
- Service
- ConfigMaps
- Secrets references for database connection

### frontend-app.yaml
Deploys the frontend application service including:
- Deployment
- Service (with LoadBalancer)
- ConfigMaps

## Usage

### Deploy All Applications (App of Apps Pattern)
```bash
kubectl apply -f bootstrap/app-of-apps.yaml
```

### Deploy Individual Applications
```bash
# Infrastructure
kubectl apply -f argocd-apps/infrastructure-app.yaml

# Backend
kubectl apply -f argocd-apps/backend-app.yaml

# Frontend
kubectl apply -f argocd-apps/frontend-app.yaml
```

## Sync Policies

All applications use automated sync with:
- **Auto-prune**: Remove resources not in Git
- **Self-heal**: Revert manual changes
- **CreateNamespace**: Automatically create target namespaces

## Projects

Applications are organized into ArgoCD projects:
- **infrastructure**: For Crossplane resources
- **applications**: For application workloads

## Important Notes

1. **Update Repository URL**: Change `YOUR_USERNAME` in the repoURL to your actual GitHub username
2. **Secrets**: Database connection secrets are created by Crossplane
3. **Dependencies**: Infrastructure should be deployed before applications
4. **Sync Order**: ArgoCD will manage sync order automatically
