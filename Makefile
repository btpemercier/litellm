# LiteLLM Makefile
# Simple Makefile for running tests and basic development tasks

.PHONY: help test test-unit test-integration lint format

# Default target
help:
	@echo "Available commands:"
	@echo "  make test               - Run all tests"
	@echo "  make test-unit          - Run unit tests"
	@echo "  make test-integration   - Run integration tests"
	@echo "  make test-unit-helm     - Run helm unit tests"

install-dev:
	poetry install --with dev

install-proxy-dev:
	poetry install --with dev,proxy-dev

lint: install-dev
	poetry run pip install types-requests types-setuptools types-redis types-PyYAML
	cd litellm && poetry run mypy . --ignore-missing-imports

# Testing
test:
	poetry run pytest tests/

test-unit:
	poetry run pytest tests/test_litellm/

test-integration:
	poetry run pytest tests/ -k "not test_litellm"

test-unit-helm:
	helm unittest -f 'tests/*.yaml' deploy/charts/litellm-helm

TIMESTAMP := $(shell date +%Y%m%d-%H%M%S)
VERSION := $(shell cat version.txt)

increment-version:
	@echo "Current version: $(VERSION)"
	@echo $$(($(VERSION) + 1)) > version.txt
	@echo "New version: $$(cat version.txt)"

docker-build: increment-version
	$(eval NEW_VERSION := $(shell cat version.txt))
	docker buildx build --tag repository.betclic.net/docker/litellm-pe:$(NEW_VERSION) -o type=image --platform=linux/amd64 .

docker-push: docker-build
	$(eval NEW_VERSION := $(shell cat version.txt))
	docker push repository.betclic.net/docker/litellm-pe:$(NEW_VERSION)