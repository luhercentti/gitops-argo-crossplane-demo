# Architecture Deep Dive

This document provides a detailed explanation of how ArgoCD and Crossplane work together in this demo.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workflow                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Developer commits to Git                                │
│  2. ArgoCD detects change                                   │
│  3. ArgoCD applies manifests to cluster                     │
│  4. Crossplane provisions infrastructure                    │
│  5. Applications consume infrastructure                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     Component Layers                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │                Git Repository                       │    │
│  │  (Source of Truth - All manifests stored here)    │    │
│  └────────────────────────────────────────────────────┘    │
│                          ▲                                   │
│                          │                                   │
│  ┌───────────────────────┴──────────────────────────┐      │
│  │              ArgoCD Control Plane                 │      │
│  │  - Application Controller                         │      │
│  │  - Repo Server                                    │      │
│  │  - API Server & UI                                │      │
│  └───────────────────────┬──────────────────────────┘      │
│                          │                                   │
│            ┌─────────────┴─────────────┐                   │
│            ▼                           ▼                    │
│  ┌──────────────────┐       ┌──────────────────┐          │
│  │   Crossplane     │       │   Applications   │          │
│  │   Resources      │       │   (Workloads)    │          │
│  └────────┬─────────┘       └─────────┬────────┘          │
│           │                           │                    │
│           ▼                           ▼                    │
│  ┌──────────────────┐       ┌──────────────────┐          │
│  │  Cloud Provider  │◄──────│  K8s Cluster     │          │
│  │  (AWS/GCP/Azure) │       │  (Running Pods)  │          │
│  └──────────────────┘       └──────────────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### ArgoCD Components

#### Application Controller
- Monitors Git repositories for changes
- Compares desired state (Git) with actual state (Cluster)
- Triggers sync operations when drift is detected
- Manages application lifecycle

**How it works:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  source:
    repoURL: https://github.com/user/repo.git  # Where to read
    path: applications/backend                  # What to deploy
  destination:
    server: https://kubernetes.default.svc     # Where to deploy
    namespace: dev
  syncPolicy:
    automated:                                  # How to deploy
      prune: true
      selfHeal: true
```

#### Repo Server
- Clones Git repositories
- Renders Helm charts, Kustomize, and plain YAML
- Provides manifests to Application Controller

#### API Server & UI
- REST API for all operations
- Web UI for visualization
- CLI interface

### Crossplane Components

#### Providers
Extensions that add support for external APIs (AWS, GCP, Azure, etc.)

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.1.0
```

Each provider:
- Adds Custom Resource Definitions (CRDs) for cloud resources
- Contains controllers that manage those resources
- Handles authentication with cloud provider

#### Composite Resource Definitions (XRDs)
Define custom APIs for your infrastructure

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
spec:
  group: custom.crossplane.io
  names:
    kind: XDatabase        # Composite (cluster-scoped)
  claimNames:
    kind: Database         # Claim (namespace-scoped)
```

#### Compositions
Templates that define how to build infrastructure from XRDs

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
spec:
  compositeTypeRef:
    apiVersion: custom.crossplane.io/v1alpha1
    kind: XDatabase
  resources:
    - name: rds-instance
      base:
        apiVersion: rds.aws.upbound.io/v1beta1
        kind: Instance
        spec:
          forProvider:
            engine: postgres
```

#### Claims
User-facing resources that request infrastructure

```yaml
apiVersion: custom.crossplane.io/v1alpha1
kind: Database
metadata:
  name: my-database
  namespace: dev
spec:
  parameters:
    size: small
    environment: dev
```

## Data Flow

### Application Deployment Flow

```
1. Developer commits change to Git
   └─> applications/backend/deployment.yaml updated

2. ArgoCD detects change (every 3 minutes or via webhook)
   └─> Repo Server clones repository
   └─> Renders manifests

3. Application Controller compares states
   └─> Desired state: Git manifests
   └─> Actual state: Cluster resources

4. Sync operation
   └─> kubectl apply to cluster
   └─> Deployment rolls out new pods

5. Health check
   └─> ArgoCD monitors pod readiness
   └─> Updates application status
```

### Infrastructure Provisioning Flow

```
1. Developer commits infrastructure claim
   └─> infrastructure/claims/dev-database.yaml

2. ArgoCD syncs to cluster
   └─> Creates Database claim in dev namespace

3. Crossplane XRD controller
   └─> Detects new Database claim
   └─> Matches to Composition via selector

4. Composition controller
   └─> Creates composite resource (XDatabase)
   └─> Renders composed resources from template

5. Provider controller
   └─> Observes RDS Instance resource
   └─> Calls AWS API to create database
   └─> Updates resource status

6. Connection secrets
   └─> Provider writes credentials to Secret
   └─> Application can consume secret
```

## GitOps Workflow

### The App of Apps Pattern

```
root-app (ArgoCD Application)
  └─> Watches: argocd-apps/
      ├─> infrastructure-app.yaml
      │   └─> Deploys: infrastructure/
      │       ├─> providers/
      │       ├─> compositions/
      │       └─> claims/
      │
      ├─> backend-app.yaml
      │   └─> Deploys: applications/backend/
      │
      └─> frontend-app.yaml
          └─> Deploys: applications/frontend/
```

**Benefits:**
- Single entry point for all deployments
- Hierarchical organization
- Easy to add new applications
- Declarative infrastructure

### Sync Waves and Dependencies

Applications can be ordered using sync waves:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploy first
```

Typical order:
1. **Wave 0**: Namespaces, CRDs
2. **Wave 1**: Crossplane providers and configurations
3. **Wave 2**: Crossplane compositions
4. **Wave 3**: Infrastructure claims
5. **Wave 4**: Applications

## Security Model

### ArgoCD Security

1. **RBAC**: Control who can deploy what
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
spec:
  destinations:
    - namespace: prod
      server: https://kubernetes.default.svc
```

2. **Git Credentials**: Stored in Kubernetes secrets
3. **API Access**: Token-based authentication
4. **UI Access**: SSO integration supported

### Crossplane Security

1. **Provider Credentials**: Stored in Kubernetes secrets
```yaml
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
spec:
  credentials:
    source: Secret
    secretRef:
      name: aws-credentials
```

2. **RBAC**: Control who can create infrastructure
3. **Cross-Resource References**: Secure secret sharing
4. **Connection Secrets**: Auto-generated credentials

## Observability

### ArgoCD Metrics

- Application sync status
- Health status
- Deployment frequency
- Sync duration

### Crossplane Metrics

- Provider health
- Resource reconciliation time
- API call rates
- Resource creation success/failure

### Integration Points

Both export Prometheus metrics:
```bash
# ArgoCD metrics
kubectl port-forward svc/argocd-metrics -n argocd 8082:8082

# Crossplane metrics
kubectl port-forward svc/crossplane -n crossplane-system 8080:8080
```

## Scaling Considerations

### ArgoCD Scaling

- **Horizontal**: Multiple replica controllers
- **Sharding**: Distribute apps across controllers
- **Resource limits**: Tune for large repos

### Crossplane Scaling

- **Provider instances**: Run multiple provider pods
- **Composition complexity**: Keep compositions focused
- **Rate limiting**: Respect cloud API limits

## Best Practices

1. **Repository Structure**
   - Separate infrastructure from applications
   - Use environments (dev/staging/prod)
   - Keep compositions reusable

2. **Sync Policies**
   - Use automated sync for lower environments
   - Manual approval for production
   - Enable self-healing for infrastructure

3. **Secret Management**
   - Never commit secrets to Git
   - Use Sealed Secrets or External Secrets
   - Leverage Crossplane secret generation

4. **Resource Organization**
   - Use namespaces for isolation
   - Apply consistent labels
   - Document XRD parameters

5. **Monitoring**
   - Set up alerts for sync failures
   - Monitor cloud resource costs
   - Track deployment metrics

## Advanced Patterns

### Multi-Cluster Deployment

ArgoCD can deploy to multiple clusters:
```yaml
destination:
  name: production-cluster
  namespace: prod
```

### Multi-Cloud Infrastructure

Crossplane can provision across clouds:
```yaml
# Use AWS for databases
kind: Database
spec:
  compositionSelector:
    matchLabels:
      provider: aws

# Use GCP for storage
kind: Storage
spec:
  compositionSelector:
    matchLabels:
      provider: gcp
```

### Progressive Delivery

Integrate with Argo Rollouts for canary deployments:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      steps:
        - setWeight: 20
        - pause: {duration: 1h}
```

## Comparison with Alternatives

### vs. Terraform + CI/CD

| Feature | ArgoCD + Crossplane | Terraform + CI/CD |
|---------|-------------------|-------------------|
| State Management | Kubernetes API | Remote backend |
| Drift Detection | Continuous | On apply |
| Self-Healing | Built-in | Requires tooling |
| Multi-tenancy | Native K8s RBAC | Complex |
| Cloud APIs | Via providers | Native |

### vs. FluxCD + Crossplane

Both are valid GitOps approaches:
- **ArgoCD**: Better UI, built-in RBAC
- **FluxCD**: More Kubernetes-native, Helm-focused

## References

- [GitOps Principles](https://opengitops.dev/)
- [ArgoCD Architecture](https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/)
- [Crossplane Concepts](https://docs.crossplane.io/latest/concepts/)
