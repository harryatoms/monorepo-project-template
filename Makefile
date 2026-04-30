APPS         := $(notdir $(patsubst %/,%,$(wildcard apps/*/)))
ENV          ?= staging
EVAL_TAG     ?= ci
CALL_CONFIGS := example
PYTHON       ?= apps/example-api/.venv/bin/python

REPO_ROOT := $(shell git rev-parse --show-toplevel)

require-app:
	@test -n "$(APP)" || (echo "Error: APP is required. Usage: make <target> APP=<app>\n  Available apps: $(APPS)" && exit 1)

require-call:
	@test -n "$(CALL)" || (echo "Error: CALL is required. Usage: make <target> CALL=<call-config>\n  Available: $(CALL_CONFIGS)" && exit 1)

ensure-mise:
	@command -v mise >/dev/null 2>&1 \
		&& mise install \
		|| echo "⚠ mise not found — tool versions will not be pinned automatically.\n  Install mise: https://mise.jdx.dev"

bootstrap: require-app ensure-mise
	$(MAKE) -C apps/$(APP) bootstrap

check: require-app
	$(MAKE) -C apps/$(APP) check

build: require-app
	$(MAKE) -C apps/$(APP) build VERSION=$(VERSION)

deploy: require-app
	$(MAKE) -C apps/$(APP) deploy ENV=$(ENV) VERSION=$(IMAGE_URI)

rollback: require-app
	$(MAKE) -C apps/$(APP) rollback ENV=$(ENV) VERSION=$(VERSION)

smoke: require-app
	$(MAKE) -C apps/$(APP) smoke APP_ENDPOINT=$(APP_ENDPOINT)

version: require-app
	$(MAKE) -C apps/$(APP) version ENV=$(ENV)

check-all:
	@for app in $(APPS); do \
		echo "=== check: $$app ==="; \
		$(MAKE) -C apps/$$app check || exit 1; \
	done

infra-generate-backend-configs:
	$(REPO_ROOT)/scripts/generate-backend-configs.sh

infra-bootstrap-init:
	terraform -chdir=$(REPO_ROOT)/infra/bootstrap init

infra-bootstrap-migrate-state: infra-generate-backend-configs
	terraform -chdir=$(REPO_ROOT)/infra/bootstrap init -migrate-state

infra-bootstrap-init-remote: infra-generate-backend-configs
	terraform -chdir=$(REPO_ROOT)/infra/bootstrap init -reconfigure

infra-bootstrap-init-local:
	rm -f $(REPO_ROOT)/infra/bootstrap/backend.tf
	terraform -chdir=$(REPO_ROOT)/infra/bootstrap init -reconfigure

infra-bootstrap-plan:
	@mkdir -p $(REPO_ROOT)/infra/.plans
	terraform -chdir=$(REPO_ROOT)/infra/bootstrap \
		plan -out=$(REPO_ROOT)/infra/.plans/bootstrap.tfplan

infra-bootstrap-apply:
	terraform -chdir=$(REPO_ROOT)/infra/bootstrap \
		apply $(REPO_ROOT)/infra/.plans/bootstrap.tfplan

infra-bootstrap-plan-destroy:
	@mkdir -p $(REPO_ROOT)/infra/.plans
	terraform -chdir=$(REPO_ROOT)/infra/bootstrap \
		plan -destroy -out=$(REPO_ROOT)/infra/.plans/bootstrap-destroy.tfplan

infra-bootstrap-destroy:
	terraform -chdir=$(REPO_ROOT)/infra/bootstrap \
		apply $(REPO_ROOT)/infra/.plans/bootstrap-destroy.tfplan

infra-init: require-app
	$(MAKE) -C apps/$(APP) infra-init ENV=$(ENV)

infra-plan: require-app
	$(MAKE) -C apps/$(APP) infra-plan ENV=$(ENV)

infra-apply: require-app
	$(MAKE) -C apps/$(APP) infra-apply ENV=$(ENV)

infra-plan-destroy: require-app
	$(MAKE) -C apps/$(APP) infra-plan-destroy ENV=$(ENV)

infra-destroy: require-app
	$(MAKE) -C apps/$(APP) infra-destroy ENV=$(ENV)

eval: require-call
	$(PYTHON) evals/scripts/run.py $(CALL) \
		--output evals/results/$(subst -,_,$(CALL))/$(EVAL_TAG).json \
		--tag $(EVAL_TAG)

eval-compare: require-call
	$(PYTHON) evals/scripts/compare.py \
		evals/baselines/$(subst -,_,$(CALL)).json \
		evals/results/$(subst -,_,$(CALL))/$(EVAL_TAG).json

eval-all:
	@for call in $(CALL_CONFIGS); do \
		echo ""; \
		echo "=== eval: $$call ==="; \
		call_dir=$$(echo "$$call" | tr '-' '_'); \
		$(PYTHON) evals/scripts/run.py $$call \
			--output evals/results/$$call_dir/$(EVAL_TAG).json \
			--tag $(EVAL_TAG) || exit 1; \
	done

eval-compare-all:
	@for call in $(CALL_CONFIGS); do \
		echo ""; \
		echo "=== compare: $$call ==="; \
		call_dir=$$(echo "$$call" | tr '-' '_'); \
		$(PYTHON) evals/scripts/compare.py \
			evals/baselines/$$call_dir.json \
			evals/results/$$call_dir/$(EVAL_TAG).json || exit 1; \
	done

eval-gate: eval-all eval-compare-all

.PHONY: require-app require-call ensure-mise bootstrap check build deploy rollback smoke version \
        check-all \
        eval eval-compare eval-all eval-compare-all eval-gate \
        infra-generate-backend-configs \
        infra-bootstrap-init infra-bootstrap-migrate-state \
        infra-bootstrap-init-remote infra-bootstrap-init-local \
        infra-bootstrap-plan infra-bootstrap-apply \
        infra-bootstrap-plan-destroy infra-bootstrap-destroy \
        infra-init infra-plan infra-apply infra-plan-destroy infra-destroy
