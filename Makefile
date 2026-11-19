ENV        ?= dev
VARS       := envs/$(ENV).tfvars
TF         := terraform
INFRA      := -chdir=infra

.PHONY: help fmt lint scan validate bootstrap init plan apply kubeconfig argocd grafana destroy

help: ## Show targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-12s %s\n", $$1, $$2}'

fmt: ## Format all Terraform
	$(TF) fmt -recursive

validate: ## terraform validate both stacks (no AWS needed)
	$(TF) -chdir=bootstrap init -backend=false -input=false >/dev/null && $(TF) -chdir=bootstrap validate
	$(TF) $(INFRA) init -backend=false -input=false >/dev/null && $(TF) $(INFRA) validate

lint: ## tflint
	tflint --init && tflint --recursive --config $(CURDIR)/.tflint.hcl

scan: ## checkov security scan
	checkov -d . --config-file .checkov.yaml --compact

bootstrap: ## One-time: state bucket + GitHub OIDC roles
	$(TF) -chdir=bootstrap init && $(TF) -chdir=bootstrap apply

init: ## Init infra with remote state (needs infra/backend.hcl)
	$(TF) $(INFRA) init -backend-config=backend.hcl -reconfigure

plan: ## Plan infra
	$(TF) $(INFRA) plan -var-file=$(VARS)

apply: ## Apply infra
	$(TF) $(INFRA) apply -var-file=$(VARS)

kubeconfig: ## Point kubectl at the cluster
	$$($(TF) $(INFRA) output -raw configure_kubectl)

argocd: ## ArgoCD UI on https://localhost:8080 (prints admin password)
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
	kubectl -n argocd port-forward svc/argocd-server 8080:443

grafana: ## Grafana on http://localhost:3000 (prints admin password)
	@kubectl -n monitoring get secret monitoring-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
	kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80

destroy: ## Tear down infra (apps first, then cluster and VPC)
	$(TF) $(INFRA) destroy -var-file=$(VARS) -target=helm_release.root_app
	$(TF) $(INFRA) destroy -var-file=$(VARS)
