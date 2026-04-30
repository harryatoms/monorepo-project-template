REPO_ROOT := $(abspath ../..)
APP_DIR   := $(abspath .)

APP_SLUG  := example-web

ENV       ?= staging
VERSION   ?=

INFRA_DIR  = $(REPO_ROOT)/infra/environments/$(ENV)/apps/$(APP_SLUG)
PLANS_DIR  = $(REPO_ROOT)/infra/.plans

.PHONY: bootstrap
bootstrap:
	$(APP_DIR)/scripts/bootstrap.sh

.PHONY: check
check:
	npm run lint
	npm run check

.PHONY: build
build:
	npm run build

.PHONY: deploy
deploy:
	$(APP_DIR)/scripts/deploy.sh

.PHONY: smoke
smoke:
	APP_ENDPOINT=$(APP_ENDPOINT) $(APP_DIR)/scripts/smoke.sh $(SMOKE_FLAGS)

.PHONY: infra-init infra-plan infra-apply infra-plan-destroy infra-destroy
infra-init:
	terraform -chdir=$(INFRA_DIR) init -backend-config=$(INFRA_DIR)/backend.hcl

infra-plan:
	mkdir -p $(PLANS_DIR)
	terraform -chdir=$(INFRA_DIR) \
		plan -out=$(PLANS_DIR)/$(ENV)-$(APP_SLUG).tfplan

infra-apply:
	terraform -chdir=$(INFRA_DIR) \
		apply $(PLANS_DIR)/$(ENV)-$(APP_SLUG).tfplan

infra-plan-destroy:
	mkdir -p $(PLANS_DIR)
	terraform -chdir=$(INFRA_DIR) \
		plan -destroy -out=$(PLANS_DIR)/$(ENV)-$(APP_SLUG)-destroy.tfplan

infra-destroy:
	terraform -chdir=$(INFRA_DIR) \
		apply $(PLANS_DIR)/$(ENV)-$(APP_SLUG)-destroy.tfplan
