# GitOps with ArgoCD and Crossplane Demo

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository demonstrates the powerful combination of **ArgoCD** and **Crossplane** to implement complete GitOps automation for both application deployment and infrastructure provisioning.

## 🎯 What This Demo Does

- **ArgoCD**: Provides GitOps continuous delivery for Kubernetes applications
- **Crossplane**: Provisions cloud infrastructure using Kubernetes CRDs
- **Together**: Creates a complete platform where infrastructure AND applications are managed declaratively from Git

### Key Features

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
├── TROUBLESHOOTING.md                # Common issues and solutions
├── LICENSE                           # MIT License
├── Makefile                          # Automation commands
│
├── setup/                            # Installation scripts
│   ├── install-argocd.sh            # ArgoCD installation
│   ├── install-crossplane.sh        # Crossplane installation
│   ├── configure-providers.sh       # AWS provider setup
│   ├── complete-setup.sh            # Full end-to-end setup
│   └── cleanup.sh                   # Remove all resources
│
├── bootstrap/                        # Bootstrap ArgoCD apps
│   ├── app-of-apps.yaml             # Root ArgoCD application
│   ├── argocd-install.yaml          # ArgoCD installation manifest
│   └── crossplane-install.yaml      # Crossplane installation manifest
│
├── argocd-apps/                      # ArgoCD Application definitions
│   ├── infrastructure-app.yaml      # Manages Crossplane resources
│   ├── backend-app.yaml             # Manages backend service
│   ├── frontend-app.yaml            # Manages frontend service
│   └── README.md                    # ArgoCD apps documentation
│
├── infrastructure/                   # Crossplane infrastructure
│   ├── providers/                   # Cloud provider configurations
│   │   ├── aws-provider.yaml        # AWS S3, RDS, EC2 providers
│   │   └── provider-config.yaml     # Provider authentication config
│   ├── compositions/                # Infrastructure blueprints
│   │   ├── database-composition.yaml # PostgreSQL RDS template
│   │   └── network-composition.yaml  # VPC networking template
│   └── claims/                      # Infrastructure requests
│       ├── dev-database.yaml        # Dev database (small)
│       ├── prod-database.yaml       # Prod database (large)
│       ├── dev-network.yaml         # Dev VPC network
│       └── s3-bucket.yaml           # S3 storage bucket
│
└── applications/                     # Demo applications
    ├── backend/                     # Backend API service
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── kustomization.yaml
    └── frontend/                    # Frontend web service
        ├── deployment.yaml
        ├── service.yaml
        └── kustomization.yaml
```

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (minikube, kind, or cloud-managed)
- `kubectl` configured and connected to your cluster
- `helm` installed (for Crossplane installation)
- AWS account with credentials (for infrastructure provisioning)

### Installation

**Option 1: Automated Setup (Recommended)**

```bash
# 1. Clone the repository
git clone https://github.com/luhercentti/gitops-argo-crossplane-demo.git
cd gitops-argo-crossplane-demo

# 2. Set AWS credentials
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key

# 3. Update repository URLs (replace 'luhercentti' with your GitHub username)
find . -type f -name "*.yaml" -exec sed -i '' 's/luhercentti/your-github-username/g' {} +

# 4. Run complete setup
make install
# OR
./setup/complete-setup.sh

# 5. Access ArgoCD UI
make port-forward
# In another terminal, get the password:
make argocd-password
```

**Option 2: Manual Step-by-Step**

```bash
# 1. Install ArgoCD
./setup/install-argocd.sh

# 2. Install Crossplane
./setup/install-crossplane.sh

# 3. Configure AWS provider
./setup/configure-providers.sh

# 4. Deploy applications
kubectl apply -f bootstrap/app-of-apps.yaml
```

### Access ArgoCD UI

```bash
# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Open in browser
open https://localhost:8080
# Username: admin
# Password: (from previous command)
```

## 🤖 How It Works - Fully Automated

### One-Time Manual Setup (Required Once)

After installing ArgoCD and Crossplane, you only need to do this **once**:

```bash
# 1. Configure AWS credentials (ONE TIME)
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
./setup/configure-providers.sh

# 2. Apply provider config (ONE TIME)
kubectl apply -f infrastructure/providers/provider-config.yaml

# 3. Bootstrap ArgoCD (ONE TIME)
kubectl apply -f bootstrap/app-of-apps.yaml
```

### After Setup - Everything is<br> Automatic! ✨

Once configured, ArgoCD has **automated sync enabled**:

```yaml
syncPolicy:
  automated:
    prune: true        # Automatically deletes removed resources
    selfHeal: true     # Automatically fixes manual changes
    allowEmpty: false
```

### Complete Automation Flow

```
┌─────────────┐
│   Git Push  │ ──┐
└─────────────┘   │
                  │ (Within 3 min)
                  ▼
         ┌──────────────┐
         │   ArgoCD     │ Auto-sync enabled
         │  Detects &   │ selfHeal: true
         │   Applies    │ prune: true
         └──────────────┘
                  │
                  │ (Immediately)
                  ▼
         ┌──────────────┐
         │  Kubernetes  │ Claim created
         │    Claim     │
         └──────────────┘
                  │
                  │ (Within 30s)
                  ▼
         ┌──────────────┐
         │  Crossplane  │ Reconciliation
         │  Controller  │ (continuous)
         └──────────────┘
                  │
                  ▼
         ┌──────────────┐
         │     AWS      │ Real resources
         │  Resources   │ created/updated
         └──────────────┘
```

### What Happens Automatically When You Push to Git

**Example: Adding a new database**

```bash
# You create and commit a new database
git add infrastructure/claims/new-database.yaml
git commit -m "Add production database"
git push
```

**ArgoCD automatically (within ~3 minutes):**
1. ✅ Detects the Git change
2. ✅ Syncs the new YAML to Kubernetes
3. ✅ Creates the Database claim

**Crossplane automatically (within seconds):**
4. ✅ Sees the new Database claim
5. ✅ Creates actual AWS RDS instance
6. ✅ Creates security groups, subnets, networking
7. ✅ Stores connection credentials in a Kubernetes Secret
8. ✅ Continuously monitors and fixes drift

**Example: Deleting infrastructure**

```bash
# You remove the database from Git
git rm infrastructure/claims/new-database.yaml
git commit -m "Remove database"
git push
```

**ArgoCD automatically:**
1. ✅ Detects deletion
2. ✅ Deletes the Kubernetes claim (because `prune: true`)

**Crossplane automatically:**
3. ✅ Deletes the AWS RDS instance
4. ✅ Deletes all related AWS resources (security groups, subnets)

### Self-Healing (Also Automatic)

If someone manually changes something:

- **Someone manually deletes your S3 bucket in AWS console**
  → Crossplane automatically recreates it within 30 seconds

- **Someone manually changes database size in AWS**
  → Crossplane automatically changes it back to match Git

- **Someone manually edits a deployment in Kubernetes**
  → ArgoCD automatically reverts it to match Git

### Monitoring the Automation

Watch everything happen in real-time:

```bash
# Terminal 1: Watch ArgoCD sync
kubectl get applications -n argocd -w

# Terminal 2: Watch Crossplane create AWS resources
kubectl get managed -w

# Terminal 3: Watch specific resource types
watch kubectl get buckets,databases,networks

# Terminal 4: Monitor Crossplane logs
kubectl logs -f -n crossplane-system -l app=crossplane
```

## 🎓 Demo Scenarios

### Scenario 1: Infrastructure Provisioning

```bash
# View what Crossplane providers are installed
kubectl get providers

# See infrastructure blueprints (Compositions)
kubectl get compositions

# View infrastructure requests (Claims)
kubectl get database,network -A

# Watch infrastructure being provisioned
kubectl get managed -w

# See connection secrets created
kubectl get secrets -n dev | grep database
```

### Scenario 2: Application Deployment

```bash
# Update application image tag
vim applications/backend/kustomization.yaml
# Change newTag: 1.25-alpine to newTag: 1.26-alpine

git add applications/backend/kustomization.yaml
git commit -m "Update backend to 1.26"
git push

# Watch ArgoCD auto-sync (within 3 minutes)
kubectl get applications -n argocd -w

# Watch rolling update
kubectl get pods -n dev -w
```

### Scenario 3: Infrastructure Modification

```bash
# Change database size from small to medium
vim infrastructure/claims/dev-database.yaml
# Change size: small to size: medium

git add infrastructure/claims/dev-database.yaml
git commit -m "Increase dev database size"
git push

# Watch Crossplane modify the RDS instance
kubectl describe database dev-database -n dev
kubectl get managed -w
```

## 🔑 Key Concepts

### ArgoCD Components

- **Application Controller**: Monitors Git repos and manages application lifecycle
- **Repo Server**: Clones repositories and renders manifests (Helm, Kustomize, plain YAML)
- **API Server & UI**: Provides REST API and web interface for management
- **App-of-Apps Pattern**: Root application that manages other applications

### Crossplane Components

- **Providers**: Extensions for cloud APIs (AWS, GCP, Azure)
  - `provider-aws-s3`: Manages S3 buckets
  - `provider-aws-rds`: Manages RDS databases
  - `provider-aws-ec2`: Manages VPCs, subnets, security groups

- **CompositeResourceDefinitions (XRDs)**: Define custom infrastructure APIs
  - `XDatabase`: API for requesting databases
  - `XNetwork`: API for requesting VPC networks

- **Compositions**: Templates that define how to build infrastructure
  - Database composition: Creates RDS + Security Groups + Subnets
  - Network composition: Creates VPC + Internet Gateway + Route Tables

- **Claims**: Requests for infrastructure
  - `dev-database`: Small PostgreSQL for development
  - `prod-database`: Large PostgreSQL for production
  - `s3-bucket`: S3 storage with versioning and encryption

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

### How They Work Together

1. **Developers** commit infrastructure/application changes to Git
2. **ArgoCD** detects changes and syncs to Kubernetes
3. **Crossplane** provisions cloud infrastructure from Kubernetes manifests
4. **Applications** consume infrastructure via Kubernetes Secrets
5. **Both systems** continuously monitor and maintain desired state

## 🔍 Verifying Crossplane Installation

Check that Crossplane components are running:

```bash
# Check Crossplane core
kubectl get pods -n crossplane-system

# Check providers are installed and healthy
kubectl get providers

# See what AWS resource types are available
kubectl api-resources | grep aws | head -20

# View infrastructure templates
kubectl get xrd,compositions

# See all AWS resources managed by Crossplane
kubectl get managed
```

## 🎯 What Gets Provisioned

### Infrastructure (via Crossplane)

When you apply the infrastructure claims, Crossplane creates:

- **RDS PostgreSQL Databases**
  - Dev: db.t3.micro with 20GB
  - Prod: db.t3.medium with 100GB
  - Automated backups and encryption
  - Connection secrets in Kubernetes

- **VPC Networking**
  - VPC with custom CIDR
  - Public subnets across availability zones
  - Internet Gateway and Route Tables
  - Security groups with appropriate rules

- **S3 Storage**
  - Bucket with versioning enabled
  - Server-side encryption (AES256)
  - Lifecycle policies and tags

### Applications (via ArgoCD)

- **Backend Service**: API application using Kustomize
- **Frontend Service**: Web application with LoadBalancer
- Both automatically connected to provisioned infrastructure

## 🛠️ Customization

### Add a New Application

```bash
# 1. Create application manifests
mkdir -p applications/new-app
# Add deployment.yaml, service.yaml, kustomization.yaml

# 2. Create ArgoCD Application
cat <<EOF > argocd-apps/new-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: new-app
  namespace: argocd
spec:
  project: applications
  source:
    repoURL: https://github.com/your-user/your-repo.git
    path: applications/new-app
  destination:
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# 3. Commit and push - ArgoCD deploys automatically
git add applications/new-app argocd-apps/new-app.yaml
git commit -m "Add new application"
git push
```

### Add New Infrastructure

```bash
# 1. Create a claim for the resource
cat <<EOF > infrastructure/claims/redis-cache.yaml
apiVersion: elasticache.aws.upbound.io/v1beta1
kind: Cluster
metadata:
  name: redis-cache
spec:
  forProvider:
    engine: redis
    nodeType: cache.t3.micro
    numCacheNodes: 1
    region: us-east-1
EOF

# 2. Commit and push - Crossplane provisions automatically
git add infrastructure/claims/redis-cache.yaml
git commit -m "Add Redis cache"
git push
```

## 🔧 Useful Commands

### ArgoCD

```bash
# View all applications
kubectl get applications -n argocd

# Force sync an application
argocd app sync <app-name>

# View application details
argocd app get <app-name>

# View sync history
argocd app history <app-name>

# Rollback to previous version
argocd app rollback <app-name> <revision-id>
```

### Crossplane

```bash
# View all providers
kubectl get providers

# View all managed resources
kubectl get managed

# View specific resource types
kubectl get buckets,instances,vpcs

# Check provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-aws-s3

# Describe a claim to see its status
kubectl describe database dev-database -n dev
```

### Cleanup

```bash
# Remove everything
make cleanup
# OR
./setup/cleanup.sh

# Or manually
kubectl delete -f bootstrap/app-of-apps.yaml
kubectl delete namespace argocd crossplane-system dev staging prod
```

## � Learning Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Crossplane Documentation](https://docs.crossplane.io/)
- [GitOps Principles](https://opengitops.dev/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Crossplane Compositions](https://docs.crossplane.io/latest/concepts/compositions/)

## ⚠️ Troubleshooting

For common issues and solutions, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Quick fixes:
- **ArgoCD won't sync**: Ensure repository URLs are updated with your GitHub username
- **Crossplane fails**: Verify AWS credentials are correctly configured
- **Pods pending**: Wait 5-10 minutes for infrastructure to provision
- **Composition errors**: Check Crossplane version compatibility (v2.x requires different format)

## 📝 Production Considerations

- Use SealedSecrets or External Secrets Operator for secret management
- Implement proper RBAC for multi-team access
- Enable ArgoCD notifications for deployment events
- Set up monitoring and alerting for Crossplane resources
- Use Crossplane composite resources for complex infrastructure patterns
- Consider backup strategies for Crossplane state

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

- ArgoCD team for the excellent GitOps tool
- Crossplane team for cloud-native infrastructure management
- Kubernetes community for the amazing ecosystem

---

**Made with ❤️ for the Platform Engineering community**
