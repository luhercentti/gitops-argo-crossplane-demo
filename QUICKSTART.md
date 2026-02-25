# Quick Start Guide

Get the demo running in 5 minutes!

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud-managed)
- `kubectl` configured and connected
- `helm` installed
- AWS account with credentials

## Step 1: Clone and Setup

```bash
git clone https://github.com/YOUR_USERNAME/gitops-argo-crossplane-demo.git
cd gitops-argo-crossplane-demo
```

## Step 2: Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
```

## Step 3: Update Repository URLs

Edit these files and replace `YOUR_USERNAME` with your GitHub username:
- `bootstrap/app-of-apps.yaml`
- `argocd-apps/infrastructure-app.yaml`
- `argocd-apps/backend-app.yaml`
- `argocd-apps/frontend-app.yaml`

Or use sed:
```bash
find . -type f -name "*.yaml" -exec sed -i '' 's/YOUR_USERNAME/your-github-username/g' {} +
```

## Step 4: Run Installation

```bash
make install
```

Or manually:
```bash
./setup/complete-setup.sh
```

## Step 5: Access ArgoCD

```bash
# In one terminal
make port-forward

# In another terminal, get the password
make argocd-password
```

Open https://localhost:8080
- Username: `admin`
- Password: (from previous command)

## Step 6: Watch It Work

```bash
# Watch applications sync
watch kubectl get applications -n argocd

# Watch infrastructure provision
watch kubectl get managed

# Watch pods
watch kubectl get pods -n dev
```

## What's Happening?

1. ArgoCD is reading your Git repository
2. It's deploying Crossplane and provider configurations
3. Crossplane is provisioning AWS resources (RDS, VPC, S3)
4. ArgoCD is deploying your applications
5. Applications connect to the infrastructure

## Next Steps

- Check out the [Demo Walkthrough](DEMO_WALKTHROUGH.md) for a detailed presentation guide
- Read the [Architecture](README.md#architecture) section
- Try making changes to applications and pushing to Git
- Explore the ArgoCD UI

## Troubleshooting

If something doesn't work, check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Common issues:
- **ArgoCD won't sync**: Update repository URLs
- **Crossplane fails**: Check AWS credentials
- **Pods pending**: Wait for infrastructure to provision (can take 5-10 minutes)

## Cleanup

When you're done:
```bash
make clean
```

This will delete all demo resources from your cluster and AWS account.
