# Makefile for RISC-V Doc Template
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
# International License. To view a copy of this license, visit
# http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to
# Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
#
# SPDX-License-Identifier: CC-BY-SA-4.0
#
# Description:
#
# This Makefile is designed to automate the process of building and packaging
# the Doc Template for RISC-V Extensions.

DOCS := \
	riscv-iommu.adoc

DATE ?= $(shell date +%Y-%m-%d)
VERSION ?= v1.0
REVMARK ?= 'This document is Ratified. See http://riscv.org/spec-state for details.'
DOCKER_IMG := riscvintl/riscv-docs-base-container-image:latest
ifneq ($(SKIP_DOCKER),true)
	DOCKER_CMD := docker run --rm -v ${PWD}:/build -w /build \
	${DOCKER_IMG} \
	/bin/sh -c
	DOCKER_QUOTE := "
endif

SRC_DIR := src
BUILD_DIR := build

DOCS_PDF := $(DOCS:%.adoc=%.pdf)
DOCS_HTML := $(DOCS:%.adoc=%.html)

PDF_THEME := docs-resources/themes/riscv-spec.yml

XTRA_ADOC_OPTS :=
ASCIIDOCTOR_PDF := asciidoctor-pdf
ASCIIDOCTOR_HTML := asciidoctor
OPTIONS := --trace \
           -a compress \
           -a mathematical-format=svg \
           -a revnumber=${VERSION} \
           -a revremark=${REVMARK} \
           -a revdate=${DATE} \
           -a pdf-fontsdir=docs-resources/fonts \
           -a pdf-theme=${PDF_THEME} \
           $(XTRA_ADOC_OPTS) \
		   -D build \
           --failure-level=ERROR
REQUIRES := --require=asciidoctor-bibtex \
            --require=asciidoctor-diagram \
			--require=asciidoctor-lists \
            --require=asciidoctor-mathematical

.PHONY: all build clean build-container build-no-container build-docs

all: build

build-docs: $(DOCS_PDF) $(DOCS_HTML)

vpath %.adoc $(SRC_DIR)

%.pdf: %.adoc
	$(DOCKER_CMD) $(DOCKER_QUOTE) $(ASCIIDOCTOR_PDF) $(OPTIONS) $(REQUIRES) $< $(DOCKER_QUOTE)

%.html: %.adoc
	$(DOCKER_CMD) $(DOCKER_QUOTE) $(ASCIIDOCTOR_HTML) $(OPTIONS) $(REQUIRES) $< $(DOCKER_QUOTE)

build:
	@echo "Checking if Docker is available..."
	@if command -v docker >/dev/null 2>&1 ; then \
		echo "Docker is available, building inside Docker container..."; \
		$(MAKE) build-container; \
	else \
		echo "Docker is not available, building without Docker..."; \
		$(MAKE) build-no-container; \
	fi

build-container:
	@echo "Starting build inside Docker container..."
	$(MAKE) build-docs
	@echo "Build completed successfully inside Docker container."

build-no-container:
	@echo "Starting build..."
	$(MAKE) SKIP_DOCKER=true build-docs
	@echo "Build completed successfully."

# Update docker image to latest
docker-pull-latest:
	docker pull ${DOCKER_IMG}

clean:
	@echo "Cleaning up generated files..."
	rm -rf $(BUILD_DIR)
	@echo "Cleanup completed."
