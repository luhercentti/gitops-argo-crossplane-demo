# Demo Walkthrough Guide

This guide provides step-by-step instructions for demonstrating ArgoCD and Crossplane working together.

## Preparation

1. Fork this repository to your GitHub account
2. Update repository URLs in:
   - `bootstrap/app-of-apps.yaml`
   - `argocd-apps/infrastructure-app.yaml`
   - `argocd-apps/backend-app.yaml`
   - `argocd-apps/frontend-app.yaml`

3. Set up AWS credentials:
```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
```

4. Run the complete setup:
```bash
chmod +x setup/*.sh
./setup/complete-setup.sh
```

## Demo Script

### Part 1: Introduction (5 minutes)

**Talking Points:**
- GitOps brings Git-based workflows to infrastructure and operations
- ArgoCD provides continuous delivery for Kubernetes
- Crossplane extends Kubernetes to manage cloud infrastructure
- Together they enable complete platform automation

### Part 2: ArgoCD Overview (10 minutes)

1. **Show ArgoCD UI**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Open https://localhost:8080

2. **Explain the App of Apps pattern**
- Show the root application
- Explain how it manages other applications
- Highlight the declarative approach

3. **Show application sync status**
```bash
kubectl get applications -n argocd
```

**Key Points:**
- Git as single source of truth
- Automated synchronization
- Visual representation of cluster state
- Rollback capabilities

### Part 3: Crossplane Overview (10 minutes)

1. **Show installed providers**
```bash
kubectl get providers
```

2. **Explain Compositions**
- Open `infrastructure/compositions/database-composition.yaml`
- Show how it abstracts RDS complexity
- Explain parameters mapping

3. **Show infrastructure claims**
```bash
kubectl get database -n dev
kubectl describe database dev-database -n dev
```

**Key Points:**
- Infrastructure as Kubernetes resources
- Self-service infrastructure
- Multi-cloud abstraction
- GitOps-compatible

### Part 4: Live Demo - Infrastructure Changes (15 minutes)

#### Scenario 1: Create a New Database

1. **Create a new database claim**
```bash
cat <<EOF > infrastructure/claims/staging-database.yaml
---
apiVersion: custom.crossplane.io/v1alpha1
kind: Database
metadata:
  name: staging-database
  namespace: staging
spec:
  parameters:
    size: medium
    environment: staging
  compositionSelector:
    matchLabels:
      provider: aws
      type: rds
  writeConnectionSecretToRef:
    name: staging-database-connection
EOF
```

2. **Commit and push**
```bash
git add infrastructure/claims/staging-database.yaml
git commit -m "Add staging database"
git push
```

3. **Watch ArgoCD sync**
```bash
# In ArgoCD UI, watch the infrastructure app sync
# Or use CLI
argocd app sync infrastructure
argocd app wait infrastructure
```

4. **Watch Crossplane provision**
```bash
kubectl get database -n staging -w
kubectl get managed
```

**Talking Points:**
- Change made in Git
- ArgoCD detects and syncs automatically
- Crossplane provisions real AWS RDS instance
- Connection secrets created automatically

#### Scenario 2: Update Application Image

1. **Update backend image**
Edit `applications/backend/kustomization.yaml`:
```yaml
images:
  - name: nginx
    newTag: 1.26-alpine  # Changed from 1.25-alpine
```

2. **Commit and push**
```bash
git add applications/backend/kustomization.yaml
git commit -m "Update backend to nginx 1.26"
git push
```

3. **Watch in ArgoCD**
```bash
# Watch the backend app sync and perform rolling update
kubectl get pods -n dev -w
```

**Talking Points:**
- Declarative image management
- Automatic rolling update
- Zero downtime deployment
- Audit trail in Git history

### Part 5: Self-Healing Demo (10 minutes)

1. **Manually delete a resource**
```bash
kubectl delete deployment backend -n dev
```

2. **Watch ArgoCD detect and fix**
```bash
# ArgoCD will detect drift and recreate the deployment
kubectl get deployment -n dev -w
```

3. **Show in ArgoCD UI**
- Point out the sync status change
- Show the auto-heal in action

**Talking Points:**
- Continuous reconciliation
- Self-healing infrastructure
- Prevents configuration drift
- Enforces desired state

### Part 6: Observability Features (5 minutes)

1. **Show ArgoCD health checks**
```bash
kubectl get applications -n argocd
```

2. **Show resource tree in UI**
- Demonstrate the visual hierarchy
- Show pod logs in UI
- Show sync history

3. **Show Crossplane resource status**
```bash
kubectl describe database dev-database -n dev
kubectl get events -n dev --sort-by='.lastTimestamp'
```

### Part 7: Rollback Demo (5 minutes)

1. **Make a breaking change**
Edit `applications/frontend/deployment.yaml`:
```yaml
image: nginx:invalid-tag
```

2. **Commit and push**
```bash
git commit -am "Breaking change"
git push
```

3. **Watch it fail**
```bash
kubectl get pods -n dev -w
```

4. **Rollback in ArgoCD**
```bash
# Via UI or CLI
argocd app rollback frontend 0
```

**Talking Points:**
- Easy rollback to any Git commit
- Full deployment history
- Quick recovery from failures

## Q&A Points

### Common Questions

**Q: How does this compare to Terraform?**
A: Crossplane uses Kubernetes API and CRDs, enabling GitOps workflows. Terraform requires separate state management. Both can coexist.

**Q: What about secrets management?**
A: Use Sealed Secrets, External Secrets Operator, or cloud-native solutions (AWS Secrets Manager, etc.). Crossplane can generate and manage secrets.

**Q: Can I use this in production?**
A: Yes! Both ArgoCD and Crossplane are CNCF projects used in production by many organizations.

**Q: What about multi-cluster?**
A: ArgoCD supports multi-cluster deployments. Crossplane can manage resources across multiple cloud providers.

**Q: Performance and scalability?**
A: ArgoCD can manage thousands of applications. Crossplane scales horizontally and supports large infrastructures.

## Cleanup

After the demo:
```bash
./setup/cleanup.sh
```

## Additional Resources

- Show the GitHub repository structure
- Point to documentation
- Mention community resources
- Share links to CNCF projects
