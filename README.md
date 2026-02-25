# GitOps with ArgoCD and Crossplane Demo

This repository demonstrates the powerful combination of **ArgoCD** and **Crossplane** to implement GitOps for both application deployment and infrastructure provisioning.

## 🎯 Overview

### What This Demo Showcases

1. **ArgoCD**: GitOps continuous delivery tool for Kubernetes
   - Declarative application deployment
   - Automated sync from Git
   - Multi-environment management
   - Self-healing capabilities

2. **Crossplane**: Universal control plane for infrastructure
   - Provision cloud resources using Kubernetes CRDs
   - Infrastructure as Code (IaC) with Kubernetes manifests
   - Multi-cloud abstraction layer
   - Composition for reusable infrastructure patterns

3. **How They Work Together**:
   - ArgoCD deploys and manages Crossplane resources from Git
   - Crossplane provisions cloud infrastructure (databases, storage, networks)
   - Applications deployed by ArgoCD consume infrastructure created by Crossplane
   - Complete GitOps workflow for apps AND infrastructure

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Git Repository                      │
│  (Single Source of Truth)                                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │     ArgoCD       │
                    │  (GitOps Engine) │
                    └──────────────────┘
                              │
                ┌─────────────┴─────────────┐
                ▼                           ▼
    ┌──────────────────────┐    ┌──────────────────────┐
    │   Crossplane CRs     │    │   Applications       │
    │ (Infrastructure)     │    │   (Workloads)        │
    └──────────────────────┘    └──────────────────────┘
                │                           │
                ▼                           ▼
    ┌──────────────────────┐    ┌──────────────────────┐
    │   Cloud Provider     │◄───│   Kubernetes Pods    │
    │   (AWS/GCP/Azure)    │    │   (App Containers)   │
    └──────────────────────┘    └──────────────────────┘
```

## 📁 Repository Structure

```
.
├── README.md                          # This file
├── setup/                             # Installation scripts
│   ├── install-argocd.sh
│   ├── install-crossplane.sh
│   └── configure-providers.sh
├── bootstrap/                         # Bootstrap ArgoCD applications
│   ├── argocd-install.yaml           # ArgoCD installation
│   ├── crossplane-install.yaml       # Crossplane installation
│   └── app-of-apps.yaml              # ArgoCD App-of-Apps pattern
├── infrastructure/                    # Crossplane resources
│   ├── providers/                    # Provider configurations
│   │   ├── aws-provider.yaml
│   │   └── provider-config.yaml
│   ├── compositions/                 # Crossplane compositions
│   │   ├── database-composition.yaml
│   │   └── network-composition.yaml
│   └── claims/                       # Infrastructure claims
│       ├── dev-database.yaml
│       └── prod-database.yaml
├── applications/                      # Demo applications
│   ├── backend/                      # Backend service
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   └── frontend/                     # Frontend service
│       ├── deployment.yaml
│       ├── service.yaml
│       └── kustomization.yaml
└── argocd-apps/                      # ArgoCD Application manifests
    ├── infrastructure-app.yaml       # Deploys Crossplane resources
    ├── backend-app.yaml              # Deploys backend
    └── frontend-app.yaml             # Deploys frontend
```

## 🚀 Getting Started

### Prerequisites

- Kubernetes cluster (minikube, kind, or cloud-managed)
- kubectl configured
- Git repository access
- Cloud provider credentials (AWS/GCP/Azure)

### Quick Start

1. **Install ArgoCD**
```bash
./setup/install-argocd.sh
```

2. **Install Crossplane**
```bash
./setup/install-crossplane.sh
```

3. **Configure Cloud Providers**
```bash
./setup/configure-providers.sh
```

4. **Deploy the Demo**
```bash
kubectl apply -f bootstrap/app-of-apps.yaml
```

5. **Access ArgoCD UI**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Username: admin
# Password: Get with: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 🎓 Demo Scenarios

### Scenario 1: Infrastructure Provisioning with GitOps

1. Commit a database claim to Git
2. ArgoCD detects the change and syncs
3. Crossplane provisions the database in the cloud
4. Application consumes the database

### Scenario 2: Application Deployment

1. Update application image tag in Git
2. ArgoCD auto-syncs the change
3. Kubernetes rolling update deploys new version
4. Zero-downtime deployment

### Scenario 3: Self-Healing

1. Manually delete a resource in cluster
2. ArgoCD detects drift from Git
3. Automatically recreates the resource
4. Cluster returns to desired state

## 🔑 Key Concepts

### ArgoCD Strengths
- **Declarative GitOps**: Git as single source of truth
- **Visibility**: Real-time application state and health
- **Rollback**: Easy rollback to any Git commit
- **Multi-cluster**: Manage multiple clusters from one place
- **RBAC**: Fine-grained access control

### Crossplane Strengths
- **Kubernetes-native**: Use kubectl for infrastructure
- **Composition**: Build reusable infrastructure modules
- **Multi-cloud**: Abstract cloud provider differences
- **Self-service**: Developers request infrastructure via CRDs
- **GitOps-ready**: Perfect fit with ArgoCD

### How They Relate
- **ArgoCD** = Deployment engine (WHAT gets deployed)
- **Crossplane** = Infrastructure provider (WHERE it runs)
- **Together** = Complete platform automation

## 📝 Notes

- This demo uses AWS provider, but can be adapted for GCP/Azure
- Secrets management should use SealedSecrets or External Secrets in production
- Consider using Crossplane's composite resources for production workloads

## 🔗 Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Crossplane Documentation](https://docs.crossplane.io/)
- [GitOps Principles](https://opengitops.dev/)

## 📄 License

MIT
