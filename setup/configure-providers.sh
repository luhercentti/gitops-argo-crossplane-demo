#!/bin/bash

set -e

echo "⚙️ Configuring Crossplane Providers..."

# Check if AWS credentials are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "⚠️ AWS credentials not found in environment variables"
    echo "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
    echo ""
    echo "Example:"
    echo "  export AWS_ACCESS_KEY_ID=your_access_key"
    echo "  export AWS_SECRET_ACCESS_KEY=your_secret_key"
    echo ""
    read -p "Do you want to enter them now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
        read -sp "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
        echo
    else
        echo "Skipping AWS provider configuration"
        exit 1
    fi
fi

# Create AWS credentials secret
echo "🔐 Creating AWS credentials secret..."
kubectl create secret generic aws-credentials \
  -n crossplane-system \
  --from-literal=credentials="[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ AWS credentials configured!"

# Apply provider configuration
echo "📦 Installing AWS provider..."
kubectl apply -f infrastructure/providers/aws-provider.yaml

# Wait for provider to be healthy
echo "⏳ Waiting for provider to be ready..."
kubectl wait --for=condition=healthy --timeout=300s provider.pkg.crossplane.io/provider-aws-s3 || true

echo "✅ Crossplane providers configured successfully!"
echo ""
echo "🔍 Check provider status:"
echo "   kubectl get providers"
echo ""
echo "🔍 Check provider configs:"
echo "   kubectl get providerconfigs"
