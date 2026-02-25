# Troubleshooting Guide

Common issues and solutions for the GitOps demo.

## ArgoCD Issues

### ArgoCD UI Not Accessible

**Symptom:** Cannot access ArgoCD UI at https://localhost:8080

**Solutions:**
```bash
# Check if ArgoCD is running
kubectl get pods -n argocd

# Verify port-forward is active
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Check service
kubectl get svc argocd-server -n argocd
```

### Cannot Login to ArgoCD

**Symptom:** Invalid username/password

**Solutions:**
```bash
# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Reset admin password
argocd account update-password
```

### Application Stuck in "OutOfSync"

**Symptom:** Application won't sync

**Solutions:**
```bash
# Force refresh
argocd app get <app-name>
argocd app sync <app-name> --force

# Check sync policy
kubectl get application <app-name> -n argocd -o yaml

# Check application logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Application Stuck in "Progressing"

**Symptom:** Application sync never completes

**Solutions:**
```bash
# Check resource status
kubectl get all -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs -n <namespace> <pod-name>
```

## Crossplane Issues

### Provider Not Installing

**Symptom:** Provider stays in "Installing" state

**Solutions:**
```bash
# Check provider status
kubectl get providers
kubectl describe provider <provider-name>

# Check package manager logs
kubectl logs -n crossplane-system deployment/crossplane

# Manually pull package
kubectl get providerrevision
```

### ProviderConfig Not Working

**Symptom:** Resources fail with authentication errors

**Solutions:**
```bash
# Verify credentials secret exists
kubectl get secret aws-credentials -n crossplane-system

# Check secret content (be careful with credentials)
kubectl get secret aws-credentials -n crossplane-system -o yaml

# Verify ProviderConfig
kubectl get providerconfig
kubectl describe providerconfig default

# Test with a simple resource
kubectl apply -f - <<EOF
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: test-bucket-$(date +%s)
spec:
  forProvider:
    region: us-east-1
  providerConfigRef:
    name: default
EOF
```

### Managed Resource Stuck

**Symptom:** Crossplane resource stays in "Creating" state

**Solutions:**
```bash
# Check resource events
kubectl describe <resource-type> <resource-name>

# Check provider logs
kubectl logs -n crossplane-system deployment/<provider-name>

# Check AWS CloudFormation (if using AWS)
aws cloudformation describe-stacks

# Force deletion if stuck
kubectl patch <resource-type> <resource-name> \
  -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### Composition Not Applied

**Symptom:** Claim doesn't create composed resources

**Solutions:**
```bash
# Check XRD is installed
kubectl get xrd

# Check Composition
kubectl get composition
kubectl describe composition <composition-name>

# Check Claim status
kubectl describe <claim-type> <claim-name> -n <namespace>

# Verify label selectors match
kubectl get composition <name> -o yaml | grep labels -A 5
```

## Infrastructure Issues

### Database Connection Fails

**Symptom:** Application can't connect to provisioned database

**Solutions:**
```bash
# Check if secret was created
kubectl get secret -n <namespace>

# Verify secret content
kubectl get secret <db-secret-name> -n <namespace> -o yaml

# Check database status
kubectl describe database <db-name> -n <namespace>

# Verify RDS instance in AWS
aws rds describe-db-instances
```

### S3 Bucket Creation Fails

**Symptom:** Bucket resource stays in error state

**Solutions:**
```bash
# Check bucket status
kubectl describe bucket <bucket-name>

# Common issues:
# 1. Bucket name already exists globally
# 2. IAM permissions insufficient
# 3. Region mismatch

# Verify permissions
aws s3api list-buckets

# Check provider credentials
kubectl get providerconfig -o yaml
```

### VPC/Network Issues

**Symptom:** Network resources fail to provision

**Solutions:**
```bash
# Check all EC2 resources
kubectl get vpc,subnet,internetgateway,routetable

# Describe specific resource
kubectl describe vpc <vpc-name>

# Check AWS console for errors
aws ec2 describe-vpcs
```

## Git/GitOps Issues

### ArgoCD Not Detecting Changes

**Symptom:** Pushed changes to Git but ArgoCD doesn't sync

**Solutions:**
```bash
# Check repository connection
argocd repo list

# Manually refresh
argocd app get <app-name> --refresh

# Check webhook (if configured)
kubectl get secret -n argocd

# Verify repo URL
kubectl get application <app-name> -n argocd -o yaml | grep repoURL
```

### Manifest Parsing Errors

**Symptom:** "Failed to load live state" or YAML errors

**Solutions:**
```bash
# Validate YAML locally
kubectl apply --dry-run=client -f <file>

# Check kubeval or kustomize
kustomize build applications/backend
kubeval applications/backend/*.yaml

# Check ArgoCD app logs
kubectl logs -n argocd deployment/argocd-repo-server
```

## Permission Issues

### RBAC Errors

**Symptom:** "User cannot perform action" errors

**Solutions:**
```bash
# Check ArgoCD RBAC
kubectl get configmap argocd-rbac-cm -n argocd -o yaml

# Check Crossplane RBAC
kubectl get clusterrolebinding | grep crossplane

# Verify service account permissions
kubectl auth can-i create databases --as=system:serviceaccount:argocd:argocd-application-controller
```

## Performance Issues

### Slow Syncs

**Symptom:** ArgoCD takes long time to sync

**Solutions:**
```bash
# Increase timeout
kubectl patch configmap argocd-cm -n argocd --patch '
data:
  timeout.reconciliation: "300s"
'

# Check resource limits
kubectl describe pod -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### High Memory Usage

**Symptom:** Pods being OOMKilled

**Solutions:**
```bash
# Increase resource limits
kubectl patch deployment crossplane -n crossplane-system --patch '
spec:
  template:
    spec:
      containers:
      - name: crossplane
        resources:
          limits:
            memory: 2Gi
'
```

## Debug Commands

### Useful Debug Commands

```bash
# Get all ArgoCD apps with status
kubectl get applications -n argocd

# Get all Crossplane managed resources
kubectl get managed

# Get all providers
kubectl get providers,providerrevisions,providerconfigs

# Full application tree
argocd app get <app-name> --show-operation

# Crossplane package debugging
kubectl get lock,configuration,provider,providerrevision

# Watch all events
kubectl get events -A --watch

# Check controller logs
kubectl logs -n argocd deployment/argocd-application-controller --tail=100 -f
kubectl logs -n crossplane-system deployment/crossplane --tail=100 -f
```

## Getting Help

1. Check official documentation:
   - [ArgoCD Docs](https://argo-cd.readthedocs.io/)
   - [Crossplane Docs](https://docs.crossplane.io/)

2. Community support:
   - ArgoCD Slack: https://argoproj.github.io/community/join-slack
   - Crossplane Slack: https://slack.crossplane.io/

3. GitHub issues:
   - ArgoCD: https://github.com/argoproj/argo-cd/issues
   - Crossplane: https://github.com/crossplane/crossplane/issues
