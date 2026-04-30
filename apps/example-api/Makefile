REPO_ROOT := $(abspath ../..)
APP_DIR   := $(abspath .)
VENV      := $(APP_DIR)/.venv

APP_SLUG  := example-api

ENV          ?= staging
VERSION      ?=

INFRA_DIR  = $(REPO_ROOT)/infra/environments/$(ENV)/apps/$(APP_SLUG)
PLANS_DIR  = $(REPO_ROOT)/infra/.plans

.PHONY: bootstrap
bootstrap:
	$(APP_DIR)/scripts/bootstrap.sh

.PHONY: check
check:
	$(VENV)/bin/ruff check .
	$(VENV)/bin/pytest

.PHONY: build
build:
ifndef VERSION
	$(error VERSION is required — e.g. make build VERSION=sha-abc123)
endif
	docker buildx build \
		--platform linux/amd64 \
		--build-arg VERSION=$(VERSION) \
		-t example-api:$(VERSION) \
		-f $(APP_DIR)/Dockerfile \
		$(REPO_ROOT)

.PHONY: deploy
deploy:
ifndef VERSION
	$(error VERSION is required — e.g. make deploy VERSION=<image-uri>)
endif
	ENV=$(ENV) IMAGE_URI=$(VERSION) $(APP_DIR)/scripts/deploy.sh

.PHONY: smoke
smoke:
	API_ENDPOINT=$(APP_ENDPOINT) $(APP_DIR)/scripts/smoke.sh

.PHONY: version
version:
	ENV=$(ENV) $(APP_DIR)/scripts/version.sh

.PHONY: rollback
rollback:
ifndef VERSION
	$(error VERSION is required — e.g. make rollback VERSION=<lambda-version-number>)
endif
	ENV=$(ENV) $(APP_DIR)/scripts/rollback.sh $(VERSION)

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
