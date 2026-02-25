.PHONY: help install install-argocd install-crossplane configure deploy clean status

# Default target
help:
	@echo "GitOps ArgoCD + Crossplane Demo"
	@echo "================================"
	@echo ""
	@echo "Available targets:"
	@echo "  make install            - Complete setup (ArgoCD + Crossplane + Apps)"
	@echo "  make install-argocd     - Install only ArgoCD"
	@echo "  make install-crossplane - Install only Crossplane"
	@echo "  make configure          - Configure Crossplane providers"
	@echo "  make deploy             - Deploy demo applications"
	@echo "  make status             - Show status of all components"
	@echo "  make clean              - Clean up everything"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - kubectl configured"
	@echo "  - helm installed"
	@echo "  - AWS credentials set (for Crossplane)"
	@echo ""

install:
	@echo "🚀 Starting complete installation..."
	./setup/complete-setup.sh

install-argocd:
	@echo "🚀 Installing ArgoCD..."
	./setup/install-argocd.sh

install-crossplane:
	@echo "🔧 Installing Crossplane..."
	./setup/install-crossplane.sh

configure:
	@echo "⚙️ Configuring Crossplane providers..."
	./setup/configure-providers.sh

deploy:
	@echo "🎯 Deploying applications..."
	@echo "Make sure you've updated the repository URLs first!"
	kubectl apply -f bootstrap/app-of-apps.yaml

status:
	@echo "📊 Cluster Status"
	@echo "================="
	@echo ""
	@echo "Namespaces:"
	@kubectl get namespaces | grep -E "(argocd|crossplane|dev|staging|prod)" || echo "No demo namespaces found"
	@echo ""
	@echo "ArgoCD Applications:"
	@kubectl get applications -n argocd 2>/dev/null || echo "ArgoCD not installed"
	@echo ""
	@echo "Crossplane Providers:"
	@kubectl get providers 2>/dev/null || echo "Crossplane not installed"
	@echo ""
	@echo "Managed Resources:"
	@kubectl get managed 2>/dev/null || echo "No managed resources"
	@echo ""
	@echo "Application Pods:"
	@kubectl get pods -n dev 2>/dev/null || echo "No dev namespace"

clean:
	@echo "🗑️ Cleaning up..."
	@read -p "This will delete all demo resources. Are you sure? (y/N) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		./setup/cleanup.sh; \
	else \
		echo "Cleanup cancelled"; \
	fi

port-forward:
	@echo "🌐 Port-forwarding ArgoCD UI to https://localhost:8080"
	@echo "Press Ctrl+C to stop"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

argocd-password:
	@echo "🔑 ArgoCD Admin Password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "Secret not found"
	@echo ""

logs-argocd:
	@echo "📋 ArgoCD Application Controller Logs:"
	kubectl logs -n argocd deployment/argocd-application-controller --tail=50 -f

logs-crossplane:
	@echo "📋 Crossplane Logs:"
	kubectl logs -n crossplane-system deployment/crossplane --tail=50 -f
