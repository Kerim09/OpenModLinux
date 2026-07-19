SHELL := /usr/bin/env bash

.PHONY: test lint

test:
	bash tests/test_smoke.sh

lint:
	@set -e; \
	if command -v shellcheck >/dev/null 2>&1; then \
	  shellcheck scripts/*.sh tests/*.sh; \
	else \
	  echo "shellcheck not installed: shell lint skipped"; \
	fi; \
	python3 -m py_compile scripts/steam-libraries.py scripts/validate-yaml.py; \
	python3 scripts/validate-yaml.py
